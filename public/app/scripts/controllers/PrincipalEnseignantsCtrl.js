'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantsCtrl',
		[ '$scope', '$rootScope', '$q', 'API', 'Annuaire',
		  function( $scope, $rootScope, $q, API, Annuaire ) {
		      $scope.annee = $rootScope.mois;
		      $scope.classe = -1;
		      $scope.mois = -1;
		      $scope.enseignant = -1;
		      $scope.classes = {};
		      $scope.details_enseignants = {};

		      $scope.pieChart = { options: $rootScope.globalPieChartOptions,
					  data: [ { color : $rootScope.theme.validated.base,
						    value: 0 },
						  { color : $rootScope.theme.filled.base,
						    value: 0 } ],
					  populate: function( data ) {
					      $scope.pieChart.data[0].value = data.validated;
					      $scope.pieChart.data[1].value = data.filled - data.validated;
					  } };

		      $scope.barChart = {
			  options: $rootScope.globalBarChartOptions,
			  data: { labels: [],
				  datasets: [
				      { fillColor : $rootScope.theme.filled.base,
					pointColor : $rootScope.theme.filled.base,
					strokeColor : $rootScope.theme.filled.stroke,
					pointStrokeColor : $rootScope.theme.filled.stroke,
					data: []
				      },
				      { fillColor : $rootScope.theme.validated.base,
					pointColor : $rootScope.theme.validated.base,
					strokeColor : $rootScope.theme.validated.stroke,
					pointStrokeColor : $rootScope.theme.validated.stroke,
					data: []
				      } ] },
			  populate: function( enseignants ) {
			      $scope.barChart.data.labels = [];
			      $scope.barChart.data.datasets[0].data = [];
			      $scope.barChart.data.datasets[1].data = [];

			      _(enseignants).each( function( enseignant ) {
				  $scope.barChart.data.datasets[0].data.push( enseignant.filled );
				  $scope.barChart.data.datasets[1].data.push( enseignant.validated );

				  $scope.barChart.data.labels.push( $scope.details_enseignants[enseignant.enseignant_id].full_name );
			      });
			  }
		      };

		      $scope.individualCharts = {
			  enseignants: [],
			  populate: function( data, details_enseignants ) {
			      $scope.individualCharts.enseignants = _.chain(data)
				  .map( function( enseignant ) {
				      return { enseignant: details_enseignants[ enseignant.enseignant_id ],
					       pieChart: { options: $rootScope.globalPieChartOptions,
							   data: [ { color : $rootScope.theme.validated.base,
								     value: enseignant.validated },
								   { color : $rootScope.theme.filled.base,
								     value: enseignant.filled - enseignant.validated } ] } };
				  })
				  .reject( function( enseignant ) {
				      return _(enseignant.pieChart.data).reduce(function( useless, slice ) {
					  return useless && slice.value === 0;
				      }, true);
				  } )
				  .value();
			  } };

		      $scope.extract_classes_promises = function( data ) {
			  return _.chain(data)
			      .pluck('classes')
			      .flatten()
			      .pluck('regroupement')
			      .uniq()
			      .map(function( regroupement_id ) {
				  return Annuaire.get_regroupement( regroupement_id );
			      })
			      .value();
		      };

		      $scope.extract_details_enseignants_promises = function( data ) {
			  return _(data).pluck('enseignant_id')
			      .map(function ( enseignant_id ) {
				  return Annuaire.get_user( enseignant_id );
			      });
		      };

		      $scope.process_data = function(  ) {
			  if ( $scope.raw_data !== undefined ) {
			      $scope.displayed_data = $scope.raw_data;

			      // filtrage sur la classe sélectionnée
			      if ( $scope.classe != -1 ) {
				  // .invert() suppose que les valeurs sont uniques
				  var id = _($scope.classes).invert()[$scope.classe];
				  $scope.displayed_data = _.chain($scope.displayed_data)
				      .map( function( enseignant ) {
					  return { enseignant_id: enseignant.enseignant_id,
						   classes: _(enseignant.classes).reject( function( classe ) {
						       return classe.regroupement != id;
						   })
						 };
				      })
				      .reject( function( enseignant ) { // TODO: chercher une meilleure solution
					  return enseignant.classes.length === 0;
				      })
				      .value();
			      }

			      // filtrage sur le mois sélectionné
			      if ( $scope.mois != -1 ) {
				  $scope.displayed_data = _($scope.displayed_data).map( function( enseignant ) {
				      return { enseignant_id: enseignant.enseignant_id,
					       classes: _(enseignant.classes).map( function( classe ) {
						   return { regroupement: classe.regroupement,
							    statistiques: _(classe.statistiques).reject( function( mois ) {
								return mois.month != $scope.mois;
							    })
							  };
					       })
					     };
				  });
			      }

			      // augmentation des données
			      $scope.displayed_data.filled = 0;
			      $scope.displayed_data.validated = 0;
			      _($scope.displayed_data).each( function( enseignant ) {
				  var stats = _(enseignant.classes).reduce( function( totaux, classe ) {
				      var stats = _(classe.statistiques).reduce( function( totaux, mois ) {
					  return { filled: totaux.filled + mois.filled,
						   validated: totaux.validated + mois.validated};
				      }, { filled: 0, validated: 0});

				      return { filled: totaux.filled + stats.filled,
					       validated: totaux.validated + stats.validated};
				  }, { filled: 0, validated: 0});
				  enseignant.filled = stats.filled;
				  enseignant.validated = stats.validated;

				  $scope.displayed_data.filled += stats.filled;
				  $scope.displayed_data.validated += stats.validated;
			      });

			      // consommation des données dans les graphiques
			      $scope.pieChart.populate( $scope.displayed_data );
			      $scope.individualCharts.populate( $scope.displayed_data, $scope.details_enseignants );
			      $scope.barChart.populate( $scope.displayed_data );
			  }
		      };

		      // Récupération et consommation des données
		      API.query_enseignants( '0134567A' ).then(
					 function success( response ) {
					     $scope.raw_data = _(response).reject( function( enseignant ) {
						 return enseignant.enseignant_id === '';
					     });

					     $q.all( $scope.extract_details_enseignants_promises( $scope.raw_data ) )
						 .then( function( enseignants ) {
						     _(enseignants).each(function( enseignant ) {
							 enseignant.matieres = _.chain(enseignant.matieres_enseignees)
							     .pluck( 'libelle_long' )
							     .uniq()
							     .value();
							 $scope.details_enseignants[enseignant.id_ent] = enseignant;
						     });

						     $q.all( $scope.extract_classes_promises( $scope.raw_data ) )
							 .then( function( classes ) {
							     _(classes).each(function( classe ) {
								 $scope.classes[classe.id] = classe.libelle !== null ? classe.libelle : classe.libelle_aaf;
							     });
							     $scope.process_data();
							 });
						 });
					 } );
		  } ] );
