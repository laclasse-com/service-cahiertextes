'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalClassesCtrl',
		[ '$scope', '$rootScope', 'APIClasse',
		  function ($scope, $rootScope, APIClasse) {
		      $scope.uai = '0134567A';
		      $scope.mois = $rootScope.mois;

		      $scope.raw_data		=    [];
		      $scope.data		=   [  ];
		      $scope.classes		=  [    ];
		      $scope.matieres		= [      ]; // bientôt Noël !
		      $scope.global_stats	=    {};

		      $scope.classeCourante	= '';
		      $scope.moisCourant	= -1;
		      $scope.matiereCourante	= -1;

		      $scope.pieChart = { options: $rootScope.globalPieChartOptions,
					  data: [ { color : $rootScope.theme.validated.base,
						    value: 0 },
						  { color : $rootScope.theme.filled.base,
						    value: 0 } ] };

		      $scope.process_data = function(  ) {
			  $scope.data = $scope.raw_data;

			  // Extraction des classes
			  $scope.classes = _($scope.data).pluck( 'regroupement_id' );

			  // filtrage sur un mois
			  if ( $scope.moisCourant != -1 ) {
			      $scope.data = $scope.data.map( function( regroupement ) {
				  return { regroupement_id: regroupement.regroupement_id,
					   matieres: regroupement.matieres.map( function( matiere ) {
					       return { matiere_id: matiere.matiere_id,
							mois: _(matiere.mois).filter( function( mois ) {
							    return mois.mois == $scope.moisCourant;
							}) };
					   }) };
			      });
			  }

			  // Filtrage sur une classe
			  if ( $scope.classeCourante !== '' ) {
			      $scope.data = _($scope.data).filter( function( r ) {
				  return r.regroupement_id == $scope.classeCourante;
			      });
			  }

			  // Extraction des matières
			  $scope.matieres = _.chain($scope.data)
			      .pluck( 'matieres' )
			      .flatten()
			      .pluck( 'matiere_id' )
			      .uniq()
			      .value();

			  // Filtrage sur une matière
			  if ( $scope.matiereCourante != -1 ) {
			      $scope.data = $scope.data.map( function( regroupement ) {
				  var matieres = _(regroupement.matieres).filter( function( r ) {
				      return r.matiere_id == $scope.matiereCourante;
				  });

				  return { regroupement_id: regroupement.regroupement_id,
					   matieres: matieres };
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
					      data: [ { color : $rootScope.theme.validated.base,
							value: regroupement.validated },
						      { color : $rootScope.theme.filled.base,
							value: regroupement.filled - regroupement.validated } ] },
				  lineChart: { options: $rootScope.globalLineChartOptions,
					       data: { labels: $scope.mois,
						       datasets: [
							   { fillColor : $rootScope.theme.filled.base,
							     pointColor : $rootScope.theme.filled.base,
							     strokeColor : $rootScope.theme.filled.stroke,
							     pointStrokeColor : $rootScope.theme.filled.stroke,
							     data: regroupement.mensuel.filled
							   },
							   { fillColor : $rootScope.theme.validated.base,
							     pointColor : $rootScope.theme.validated.base,
							     strokeColor : $rootScope.theme.validated.stroke,
							     pointStrokeColor : $rootScope.theme.validated.stroke,
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
								  { fillColor : $rootScope.theme.filled.base,
								    pointColor : $rootScope.theme.filled.base,
								    strokeColor : $rootScope.theme.filled.stroke,
								    pointStrokeColor : $rootScope.theme.filled.stroke,
								    data: monthlyLineChart_data.filled
								  },
								  // 1: saisies validées
								  { fillColor : $rootScope.theme.validated.base,
								    pointColor : $rootScope.theme.validated.base,
								    strokeColor : $rootScope.theme.validated.stroke,
								    pointStrokeColor : $rootScope.theme.validated.stroke,
								    data: monthlyLineChart_data.validated
								  } ] } };


			  $scope.global_stats = $scope.data.reduce( function( totaux, regroupement ) {
			      return { filled: totaux.filled + regroupement.filled,
				       validated: totaux.validated + regroupement.validated };
			  }, { filled: 0, validated: 0 });

			  $scope.pieChart.data[0].value = $scope.global_stats.validated;
			  $scope.pieChart.data[1].value = $scope.global_stats.filled - $scope.global_stats.validated;
		      };

		      APIClasse.query( { uai: $scope.uai, id: '' },
				       function( response ) {
					   $scope.raw_data = response;
					   $scope.process_data();
				       });
		  } ] );
