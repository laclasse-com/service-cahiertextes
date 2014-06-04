'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalClassesCtrl',
		[ '$scope', 'THEME', '$locale', '$q', 'API', 'Annuaire', 'User',
		  function ( $scope, THEME, $locale, $q, API, Annuaire, User ) {
		      $scope.empty = false;

		      User.get_user().then( function( response ) {
			  var current_user = response.data;
			  $scope.raw_data	 = [];
			  $scope.displayed_data  = [];
			  $scope.classes	 = {};
			  $scope.matieres	 = [];
			  $scope.annee = $locale.DATETIME_FORMATS.MONTH;

			  $scope.classe		 = null;
			  $scope.moisCourant	 = null;
			  $scope.matiereCourante = null;

			  $scope.global_stats    = { filled: 0,
						     validated: 0 };

			  $scope.xFunction = function(){ return function(d) { return d.label; }; };
			  $scope.yFunction = function(){ return function(d) { return d.value; }; };
			  $scope.descriptionFunction = $scope.xFunction;
			  $scope.colorFunction = function() {
			      var couleurs = [ THEME.validated.base, THEME.filled.base ];
			      return function( d, i ) {
				  return couleurs[ i ];
			      };
			  };
			  $scope.xAxisTickFormatFunction = function() { return function( d ) { return d; }; };

			  $scope.pieChart = { data: [ { label: 'saisie',
							value: 0 },
						      { label: 'valide',
							value: 0 } ],
					      populate: function( data ) {
						  $scope.pieChart.data[0].value = data.filled - data.validated;
						  $scope.pieChart.data[1].value = data.validated;
					      } };

			  $scope.monthlyBarChart = { data: [],
						     populate: function( data ) {
							 var data_bootstrap = [];
							 _(12).times( function( i ) { data_bootstrap.push( [ $scope.annee[ i ], 0 ] ); } );

							 var monthlyBarChart_data = data.reduce( function( monthly_stats, regroupement ) {
							     _(regroupement.mensuel.filled.length).times( function( i ) {
								 monthly_stats.filled[ i ][1] += regroupement.mensuel.filled[i];
								 monthly_stats.validated[ i ][1] += regroupement.mensuel.validated[i];
							     });
							     return monthly_stats;
							 }, { filled: data_bootstrap,
							      validated: data_bootstrap });

							 $scope.monthlyBarChart.data[ 0 ] = { key: 'saisie',
											      area: true,
											      color: THEME.filled.base,
											      values: monthlyBarChart_data.filled };
							 $scope.monthlyBarChart.data[ 1 ] = { key: 'valide',
											      area: false,
											      color: THEME.validated.base,
											      values: monthlyBarChart_data.validated};
						     } };

			  $scope.individualCharts = { classes: [],
						      populate: function( data, classes ) {
							  var hashed_classes = _.chain(classes).map( function(c) { return [ c.id, c ]; } ).object().value();
							  $scope.individualCharts.classes = _.chain(data)
							      .map( function( regroupement ) {
								  return { regroupement: hashed_classes[ regroupement.regroupement_id ],
									   pieChart: { data: [ { label: 'valide',
												 value: regroupement.validated },
											       { label: 'saisie',
												 value: regroupement.filled - regroupement.validated } ] } };
							      })
							      .value();
						      } };

			  $scope.extract_matieres = function( data ) {
			      return _.chain(data)
				  .pluck( 'matieres' )
				  .flatten()
				  .pluck( 'matiere_id' )
				  .uniq()
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


				  // Filtrage sur une seule classe
				  if ( $scope.classe != null ) {
				      $scope.displayed_data = _($scope.raw_data).filter( function( creneau ) {
					  return creneau.regroupement_id == ''+$scope.classe;
				      });
				  }

				  // Filtrage sur une matière
				  if ( $scope.matiereCourante != null ) {
				      $scope.displayed_data = $scope.displayed_data.map( function( regroupement ) {
					  var matieres = _(regroupement.matieres).filter( function( r ) {
					      return r.matiere_id == $scope.matiereCourante;
					  });

					  return { regroupement_id: regroupement.regroupement_id,
						   matieres: matieres };
				      });
				  }

				  // filtrage sur un mois
				  if ( $scope.moisCourant != null ) {
				      $scope.displayed_data = $scope.displayed_data.map( function( regroupement ) {
					  return { regroupement_id: regroupement.regroupement_id,
						   matieres: regroupement.matieres.map( function( matiere ) {
						       return { matiere_id: matiere.matiere_id,
								mois: _(matiere.mois).filter( function( mois ) {
								    return mois.mois == $scope.moisCourant;
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
				  $scope.monthlyBarChart.populate( $scope.displayed_data );
			      }
			  };

			  API.query_classes( { uai: current_user['profil_actif']['uai'] } )
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
		      } );
		  } ] );
