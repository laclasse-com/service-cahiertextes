'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('PrincipalClassesCtrl',
		[ '$scope', 'THEME', '$locale', '$q', 'API', 'Annuaire', 'current_user', 'PIECHART_DEFINITION', 'BARCHART_DEFINITION',
		  function ( $scope, THEME, $locale, $q, API, Annuaire, current_user, PIECHART_DEFINITION, BARCHART_DEFINITION ) {
		      $scope.empty = false;
		      $scope.scope = $scope;

		      $scope.raw_data	 = [];
		      $scope.displayed_data  = [];
		      $scope.classes	 = {};
		      $scope.matieres	 = [];
		      $scope.annee = _($locale.DATETIME_FORMATS.MONTH).toArray();

		      $scope.selected_regroupement_id		 = null;
		      $scope.selected_mois	 = null;
		      $scope.selected_matiere = null;

		      $scope.global_stats    = { filled: 0,
						 validated: 0 };

		      $scope.pieChart = PIECHART_DEFINITION();
		      $scope.barChart = BARCHART_DEFINITION();
		      $scope.pieChart.populate = function( data ) {
			  $scope.pieChart.data = [ { label: 'saisie',
						     value: data.filled - data.validated },
						   { label: 'valide',
						     value: data.validated } ];
		      };
		      $scope.barChart.populate = function( data ) {
			  var data_bootstrap = [];
			  _(12).times( function( i ) { data_bootstrap.push( [ $scope.annee[ i ], 0 ] ); } );

			  var barChart_data = data.reduce( function( monthly_stats, regroupement ) {
			      _(12).times( function( i ) {
				  monthly_stats.filled[ i ][ 1 ] += regroupement.mensuel.filled[i];
				  monthly_stats.validated[ i ][ 1 ] += regroupement.mensuel.validated[i];
			      });
			      return monthly_stats;
			  }, { filled: angular.copy( data_bootstrap ),
			       validated: angular.copy( data_bootstrap ) } );

			  $scope.barChart.data = [];
			  $scope.barChart.data.push( { key: 'saisie',
						       values: barChart_data.filled } );
			  $scope.barChart.data.push( { key: 'valide',
						       values: barChart_data.validated} );
		      };

		      $scope.individualCharts = { classes: [],
						  populate: function( data, classes ) {
						      var hashed_classes = _.chain(classes).map( function(c) { return [ c.id, c ]; } ).object().value();
						      $scope.individualCharts.classes = _(data)
							  .map( function( regroupement ) {
							      var individualChart = { regroupement: hashed_classes[ regroupement.regroupement_id ],
										      pieChart: PIECHART_DEFINITION() };
							      individualChart.pieChart.data = [ { label: 'saisie',
												  value: regroupement.filled - regroupement.validated },
												{ label: 'valide',
												  value: regroupement.validated } ];
							      return individualChart;
							  });
						  } };

		      $scope.extract_matieres = function( data ) {
			  return _.chain(data)
			      .pluck( 'matieres' )
			      .flatten()
			      .pluck( 'matiere_id' )
			      .uniq()
			      .compact()
			      .map( function( matiere_id ) {
				  var matiere = { id: matiere_id,
						  libelle: 'Matière inconnue !' };
				  Annuaire.get_matiere( matiere_id ).$promise.then(
				      function success( response ) {
					  matiere.libelle = response.libelle_long;
				      });
				  return matiere;
			      })
			      .value();
		      };

		      $scope.extract_classes = function( data ) {
			  return _.chain( data )
			      .pluck( 'regroupement_id' )
			      .map( function( regroupement_id ) {
				  return Annuaire.get_regroupement( regroupement_id ).$promise;
			      })
			      .value();
		      };

		      $scope.process_data = function(  ) {
			  if ( $scope.raw_data.length > 0 ) {
			      $scope.displayed_data = $scope.raw_data;

			      // Filtrage sur un regroupement
			      if ( $scope.selected_regroupement_id != null ) {
				  $scope.displayed_data = _($scope.displayed_data).select( function( regroupement ) {
				      return regroupement.regroupement_id == $scope.selected_regroupement_id;
				  } );
			      }

			      // Filtrage sur une matière
			      if ( $scope.selected_matiere != null ) {
				  $scope.displayed_data = $scope.displayed_data.map( function( regroupement ) {
				      var matieres = _(regroupement.matieres).filter( function( r ) {
					  return r.matiere_id == $scope.selected_matiere;
				      });

				      return { regroupement_id: regroupement.regroupement_id,
					       matieres: matieres };
				  });
			      }

			      // filtrage sur un mois
			      if ( $scope.selected_mois != null ) {
				  $scope.displayed_data = $scope.displayed_data.map( function( regroupement ) {
				      return { regroupement_id: regroupement.regroupement_id,
					       matieres: regroupement.matieres.map( function( matiere ) {
						   return { matiere_id: matiere.matiere_id,
							    mois: _(matiere.mois).filter( function( mois ) {
								return mois.mois == $scope.selected_mois;
							    }) };
					       }) };
				  });
			      }

			      // Calcul des statistiques mensuelles et par regroupement
			      _($scope.displayed_data).each( function( regroupement ) {
				  // stats mensuelles
				  regroupement.mensuel = regroupement.matieres.reduce( function( monthly_stats, matiere ) {
				      _(matiere.mois).each( function( mois ) {
					  monthly_stats.filled[ mois.mois - 1 ] += mois.filled;
					  monthly_stats.validated[ mois.mois - 1 ] += mois.validated;
				      });
				      return monthly_stats;
				  }, { filled: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				       validated:  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] });

				  // sommes
				  regroupement.filled = regroupement.mensuel.filled.reduce( function(total, mensuel) {
				      return total + mensuel;
				  }, 0);
				  regroupement.validated = regroupement.mensuel.validated.reduce( function(total, mensuel) {
				      return total + mensuel;
				  }, 0);
			      });

			      var global_stats = $scope.displayed_data.reduce( function( totaux, regroupement ) {
				  return { filled: totaux.filled + regroupement.filled,
					   validated: totaux.validated + regroupement.validated };
			      }, { filled: 0, validated: 0 });

			      $scope.displayed_data.filled = global_stats.filled;
			      $scope.displayed_data.validated = global_stats.validated;

			      // consommation des données dans les graphiques
			      $scope.individualCharts.populate( $scope.displayed_data, $scope.classes );
			      $scope.pieChart.populate( $scope.displayed_data );
			      $scope.barChart.populate( $scope.displayed_data );
			  }
		      };

		      API.query_classes( { uai: current_user['profil_actif']['etablissement_code_uai'] } )
			  .$promise.then( function( response ) {
			      $scope.raw_data = response;

			      $scope.empty = _($scope.raw_data[ 0 ]).size() == 0;

			      if ( ! $scope.empty ) {
				  // Extraction des matières
				  $q.all( $scope.extract_matieres( $scope.raw_data ) )
				      .then( function( response ) {
					  $scope.matieres = response;

					  // Extraction des classes
					  $q.all( $scope.extract_classes( $scope.raw_data ) )
					      .then( function( response ) {
						  $scope.classes = response;

						  $scope.process_data();
					      });
				      });
			      }
			  });

		      angular.element('#ui-view-content').after( current_user.marqueur_xiti );
		  } ] );
