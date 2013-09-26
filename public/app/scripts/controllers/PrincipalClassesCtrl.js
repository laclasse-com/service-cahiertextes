'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalClassesCtrl',
		[ '$scope', '$rootScope', 'EmploiDuTemps', 'ClasseAPI',
		  function ($scope, $rootScope, EmploiDuTemps, ClasseAPI) {
		      $scope.uai = '0134567A';

		      $scope.raw_data		=     [];
		      $scope.data		=    [  ];
		      $scope.mois		=   [    ];
		      $scope.classes		=  [      ];
		      $scope.matieres		= [        ]; // bientôt Noël !
		      $scope.global_stats	=     {};

		      $scope.classeCourante	= '';
		      $scope.moisCourant	= -1;
		      $scope.matiereCourante	= -1;

		      $scope.pieChart = { options: $rootScope.globalPieChartOptions,
					  data: [ { color : "#00ff00",
						    value: 0 },
						  { color : "#aaffaa",
						    value: 0 } ] };

		      EmploiDuTemps.getMois().success( function( response ) {
			  $scope.mois = response.mois;
		      });

		      $scope.process_data = function(  ) {
			  // Extraction des classes
			  $scope.classes = _($scope.raw_data).pluck( 'regroupement_id' );

			  // Extraction des matières
			  $scope.matieres = _.chain($scope.raw_data)
			      .pluck( 'matiere_id' )
			      .flatten()
			      .uniq()
			      .value();

			  // Filtrage des données
			  $scope.data = $scope.raw_data;

			  if ( $scope.classeCourante !== '' ) {
			      $scope.data = _($scope.data).filter( function( r ) {
				  return r.regroupement_id == $scope.classeCourante;
			      });
			  }

			  if ( $scope.matiereCourante != -1 ) {
			      $scope.data = $scope.data.map( function( regroupement ) {
				  var matieres = _(regroupement.matieres).filter( function( r ) {
				      return r.matiere_id == $scope.matiereCourante;
				  });

				  return {
				      "regroupement_id": regroupement.regroupement_id,
				      "matieres": matieres
				  };
			      });
			  }

			  if ( $scope.moisCourant != -1 ) {
			      $scope.data = $scope.data.map(
				  function( regroupement ) {
				      return {
					  "regroupement_id": regroupement.regroupement_id,
					  "matieres": regroupement.matieres.map(
					      function( matiere ) {
						  var un_mois = _(matiere.mois).filter( function( mois ) {
						      return mois.mois == $scope.moisCourant;
						  });
						  return { matiere_id: matiere.matiere_id,
							   mois: un_mois };
					      })
				      };
				  });
			  }

			  // Calcul des statistiques
			  _($scope.data).each( function( regroupement ) {
			      // stats mensuelles
			      regroupement.mensuel = regroupement.matieres.reduce(
				  function( monthly_stats, matiere ) {
				      _(matiere.mois).each( function( mois ) {
					  monthly_stats.filled[ mois.mois - 1 ] += mois.filled;
					  monthly_stats.validated[ mois.mois - 1 ] += mois.validated;
				      });
				      return monthly_stats;
				  },
				  { filled: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				    validated:  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] });

			      // sommes
			      regroupement.filled = regroupement.mensuel.filled.reduce( function(total, mensuel) {
				  return total + mensuel;
			      }, 0);
			      regroupement.validated = regroupement.mensuel.validated.reduce( function(total, mensuel) {
				  return total + mensuel;
			      }, 0);
			  });

			  $scope.individualCharts = $scope.data.map( function( regroupement ) {
			      return {
				  regroupement_id: regroupement.regroupement_id,
				  pieChart: { options: $rootScope.globalPieChartOptions,
					      data: [ { color : "#00ff00",
							value: regroupement.validated },
						      { color : "#aaffaa",
							value: regroupement.filled - regroupement.validated } ] },
				  lineChart: { options: $rootScope.globalLineChartOptions,
					       data: { labels: $scope.mois,
						       datasets: [
							   { fillColor : "#aaffaa", pointColor : "#aaffaa",
							     strokeColor : "#88aa88", pointStrokeColor : "#88aa88",
							     data: regroupement.mensuel.filled
							   },
							   { fillColor : "#00ff00", pointColor : "#00ff00",
							     strokeColor : "#00aa00", pointStrokeColor : "#00aa00",
							     data: regroupement.mensuel.validated
							   } ] } }
			      };
			  });

			  var monthlyLineChart_data = $scope.data.reduce(
			      function( monthly_stats, regroupement ) {
				  _(regroupement.mensuel.filled.length).times( function( i ) {
				      monthly_stats.filled[i] += regroupement.mensuel.filled[i];
				      monthly_stats.validated[i] += regroupement.mensuel.validated[i];
				  });
				  return monthly_stats;
			      }, { filled: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				   validated:  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] });

			  $scope.monthlyLineChart = { options: $rootScope.globalLineChartOptions,
						      data: { labels: $scope.mois,
							      datasets: [
								  // 0: saisies totales
								  { fillColor : "#aaffaa", pointColor : "#aaffaa",
								    strokeColor : "#88aa88", pointStrokeColor : "#88aa88",
								    data: monthlyLineChart_data.filled
								  },
								  // 1: saisies validées
								  { fillColor : "#00ff00", pointColor : "#00ff00",
								    strokeColor : "#00aa00", pointStrokeColor : "#00aa00",
								    data: monthlyLineChart_data.validated
								  } ] } };


			  $scope.global_stats = $scope.data.reduce( function( totaux, regroupement ) {
			      return { filled: totaux.filled + regroupement.filled,
				       validated: totaux.validated + regroupement.validated };
			  }, { filled: 0, validated: 0 });

			  $scope.pieChart.data[0].value = $scope.global_stats.validated;
			  $scope.pieChart.data[1].value = $scope.global_stats.filled - $scope.global_stats.validated;
		      };

		      ClasseAPI.query( { uai: $scope.uai, id: '' },
				       function( response ) {
					   $scope.raw_data = response;
					   $scope.process_data();
				       });
		  } ] );
