'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantsCtrl',
		[ '$scope', '$locale', 'THEME', '$q', 'API', 'Annuaire', 'User',
		  function( $scope, $locale, THEME, $q, API, Annuaire, User ) {
		      $scope.annee = $locale.DATETIME_FORMATS.MONTH;
		      $scope.classe = null;
		      $scope.mois = null;
		      $scope.classes = {};
		      $scope.details_enseignants = {};

		      $scope.xFunction = function(){ return function(d) { return d.label; }; };
		      $scope.yFunction = function(){ return function(d) { return d.value; }; };
		      $scope.descriptionFunction = $scope.xFunction;
		      $scope.colorFunction = function() {
			  var couleurs = [ THEME.validated.base, THEME.filled.base ];
			  return function( d, i ) {
			      return couleurs[ i ];
			  };
		      };
		      $scope.barChartxAxisTickFormatFunction = function() { return function( d ) { return d; }; };
		      $scope.barChartTooltipContent = function() { 
			  return function( key, x, y, e, graph ) {
			      return '<h2>' + key + '</h2><p>' + x + ' : ' + x + '</p>';
			  };
		      };
		      $scope.pieChart = { data: [ { label: 'valide',
						    value: 0 },
						  { label: 'saisie',
						    value: 0 } ],
					  populate: function( data ) {
					      $scope.pieChart.data[0].value = data.validated;
					      $scope.pieChart.data[1].value = data.filled - data.validated;
					  } };

		      $scope.barChart = {
			  data: [],
			  populate: function( enseignants ) {
			      var saisies = { key: "saisie", values: [] };
			      var valides = { key: "valide", values: [] };

			      _(enseignants).each( function( enseignant ) {
				  saisies.values.push( [ $scope.details_enseignants[enseignant.enseignant_id].full_name, enseignant.filled ] );
				  valides.values.push( [ $scope.details_enseignants[enseignant.enseignant_id].full_name, enseignant.validated ] );
			      } );

			      $scope.barChart.data = [ valides, saisies ];
			  }
		      };

		      $scope.individualCharts = {
			  enseignants: [],
			  populate: function( data, details_enseignants ) {
			      $scope.individualCharts.enseignants = _.chain(data)
				  .map( function( enseignant ) {
				      return { enseignant: details_enseignants[ enseignant.enseignant_id ],
					       pieChart: { data: [ { label: 'valide',
								     value: enseignant.validated },
								   { label: 'saisie',
								     value: enseignant.filled - enseignant.validated } ] } };
				  })
				  .value();
			  } };

		      $scope.extract_classes_promises = function( data ) {
			  return _.chain(data)
			      .pluck('classes')
			      .flatten()
			      .pluck('regroupement')
			      .uniq()
			      .reject(function( regroupement_id ) {
				  return ( regroupement_id === '' );
			      })
			      .map(function( regroupement_id ) {
				  return Annuaire.get_regroupement( regroupement_id ).$promise;
			      })
			      .value();
		      };

		      $scope.extract_details_enseignants_promises = function( data ) {
			  return _(data).pluck('enseignant_id')
			      .map(function ( enseignant_id ) {
				  return Annuaire.get_user( enseignant_id ).$promise;
			      });
		      };

		      $scope.process_data = function(  ) {
			  if ( $scope.raw_data !== undefined ) {
			      $scope.displayed_data = $scope.raw_data;

			      // filtrage sur la classe sélectionnée
			      if ( $scope.classe != null ) {
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
			      if ( $scope.mois != null ) {
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
		      User.get_user().then( function( response ) {
			  var current_user = response.data;
			  API.query_enseignants( { uai: current_user['profil_actif']['uai'] } )
			      .$promise.then( function success( response ) {
				  $scope.raw_data = _(response).reject( function( enseignant ) {
				      return enseignant.enseignant_id === '';
				  });

			      $q.all( $scope.extract_details_enseignants_promises( $scope.raw_data ) )
				  .then( function( enseignants ) {
				      _(enseignants).each(function( enseignant ) {
					  enseignant.matieres = _.chain(enseignant.classes)
					      .pluck( 'matiere_libelle' )
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
		      } );

		  } ] );
