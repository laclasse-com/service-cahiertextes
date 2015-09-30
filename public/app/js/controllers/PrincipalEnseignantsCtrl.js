'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('PrincipalEnseignantsCtrl',
		[ '$scope', '$locale', 'THEME', '$q', 'API', 'Annuaire', 'current_user', 'PIECHART_DEFINITION', 'BARCHART_DEFINITION',
		  function( $scope, $locale, THEME, $q, API, Annuaire, current_user, PIECHART_DEFINITION, BARCHART_DEFINITION ) {
		      $scope.scope = $scope;
		      $scope.annee = _($locale.DATETIME_FORMATS.MONTH).toArray();
		      $scope.selected_regroupement_id = null;
		      $scope.selected_mois = null;
		      $scope.classes = [ ];
		      var details_enseignants = {};

		      $scope.htmlify_classes_list = function( classes ) {
			  return 'Classes : <ul><li>' + _(classes).map( function( classe ) { return classe.classe_libelle; } ).join( '</li><li>' ) + '</li></ul>';
		      };

		      $scope.htmlify_matieres_list = function( matieres ) {
			  return 'Matières : <ul><li>' + matieres.join( '</li><li>' ) + '</li></ul>';
		      };

		      $scope.pieChart = PIECHART_DEFINITION();
		      $scope.barChart = BARCHART_DEFINITION();

		      $scope.pieChart.populate = function( data ) {
			  $scope.pieChart.data = [ { label: 'saisies',
						     value: data.filled - data.validated },
						   { label: 'visas',
						     value: data.validated } ];
		      };

		      $scope.barChart.populate = function( enseignants ) {
			  var saisies = { key: "saisies", values: [ ] };
			  var valides = { key: "visas", values: [ ] };

			  _(enseignants).each( function( enseignant ) {
			      saisies.values.push( [ details_enseignants[ enseignant.enseignant_id ].full_name, enseignant.filled ] );
			      valides.values.push( [ details_enseignants[ enseignant.enseignant_id ].full_name, enseignant.validated ] );
			  } );

			  $scope.barChart.data = [ valides, saisies ];
		      };

		      $scope.process_data = function(  ) {
			  if ( $scope.raw_data !== undefined ) {
			      var displayed_data = $scope.raw_data;

			      // filtrage sur la classe sélectionnée
			      if ( $scope.selected_regroupement_id != null ) {
				  displayed_data = _.chain(displayed_data)
				      .reject( function( enseignant ) {
					  return _.chain(details_enseignants[ enseignant.enseignant_id ].classes)
					      .findWhere({ classe_id: parseInt( $scope.selected_regroupement_id ) })
					      .isUndefined()
					      .value();
				      })
				      .map( function( enseignant ) {
					  return { enseignant_id: enseignant.enseignant_id,
						   classes: _(enseignant.classes).reject( function( classe ) {
						       return classe.regroupement_id != $scope.selected_regroupement_id;
						   })
						 };
				      })
				      .value();
			      }

			      // filtrage sur le mois sélectionné
			      if ( $scope.selected_mois != null ) {
				  displayed_data = _(displayed_data).map( function( enseignant ) {
				      return { enseignant_id: enseignant.enseignant_id,
					       classes: _(enseignant.classes).map( function( classe ) {
						   return { regroupement_id: classe.regroupement_id,
							    statistiques: _(classe.statistiques).reject( function( mois ) {
								return mois.month != $scope.selected_mois;
							    })
							  };
					       })
					     };
				  });
			      }

			      // tri et calcul des données
			      displayed_data.filled = 0;
			      displayed_data.validated = 0;
			      _(displayed_data).each( function( enseignant ) {
				  // mise à jour stats globales
				  displayed_data.filled += stats_enseignant.filled;
				  displayed_data.validated += stats_enseignant.validated;
			      });

			      // consommation des données dans les graphiques
			      $scope.pieChart.populate( displayed_data );
			      $scope.barChart.populate( displayed_data );
			  }
		      };

		      $scope.individualCharts = {
			  enseignants: [ ],
			  add: function( enseignant, details_enseignant ) {
			      var individualChart = { enseignant: details_enseignants[ enseignant.enseignant_id ],
						      pieChart: PIECHART_DEFINITION() };
			      individualChart.pieChart.data = [ { label: 'visas',
								  value: enseignant.validated },
								{ label: 'saisies',
								  value: enseignant.filled - enseignant.validated } ];
			      $scope.individualCharts.enseignants.push( individualChart );
			  }
		      };

		      // Récupération et consommation des données
		      API.query_enseignants( { uai: current_user[ 'profil_actif' ][ 'etablissement_code_uai' ] } )
			  .$promise.then( function success( response ) {
			      $scope.raw_data = _(response).reject( function( enseignant ) {
				  return enseignant.enseignant_id === '';
			      });

			      _($scope.raw_data).each( function( enseignant ) {
				  Annuaire.get_user( enseignant.enseignant_id ).$promise
				      .then( function( enseignant_annuaire ) {
					  enseignant_annuaire.matieres = _.chain(enseignant_annuaire.classes)
					      .pluck( 'matiere_libelle' )
					      .uniq()
					      .value();


					  details_enseignants[ enseignant_annuaire.id_ent ] = enseignant_annuaire;

					  var stats_enseignant = _(enseignant.classes).reduce( function( totaux, classe ) {
					      var stats_classe = _(classe.statistiques).reduce( function( totaux, mois ) {
						  return { filled: totaux.filled + mois.filled,
							   validated: totaux.validated + mois.validated};
					      }, { filled: 0, validated: 0});

					      return { filled: totaux.filled + stats_classe.filled,
						       validated: totaux.validated + stats_classe.validated};
					  }, { filled: 0, validated: 0});

					  // stats de l'enseignant
					  enseignant.filled = stats_enseignant.filled;
					  enseignant.validated = stats_enseignant.validated;

					  $scope.classes = $scope.classes.concat( _(enseignant_annuaire.classes)
										  .map( function( regroupement ) {
										      return { id: regroupement.classe_id,
											       libelle: regroupement.classe_libelle,
											       type: 'classe' };
										  } ) );
					  $scope.classes = $scope.classes.concat( _(enseignant_annuaire.groupes_eleves)
										  .map( function( regroupement ) {
										      return { id: regroupement.groupe_id,
											       libelle: regroupement.groupe_libelle,
											       type: 'groupe' };
										  } ) );

					  $scope.classes = _($scope.classes).uniq( function( regroupement ) { return regroupement.id; } );

					  $scope.individualCharts.add( enseignant, enseignant_annuaire );
				      } );

			      } );

			      // $scope.process_data();
			  } );

		      angular.element('#ui-view-content').after( current_user.marqueur_xiti );
		  } ] );
