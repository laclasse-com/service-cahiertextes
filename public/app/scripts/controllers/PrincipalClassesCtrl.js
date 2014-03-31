'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalClassesCtrl',
		[ '$scope', '$rootScope', '$q', 'API', 'Annuaire', 'User',
		  function ( $scope, $rootScope, $q, API, Annuaire, User ) {
		      $scope.empty = false;

		      User.get_user().then( function( response ) {
			  var current_user = response.data;
			  $scope.raw_data	 =   [];
			  $scope.displayed_data  =  [  ];
			  $scope.classes	 = {    };
			  $scope.matieres	 =   []; // bientôt Noël !

			  $scope.classe		 = null;
			  $scope.moisCourant	 = null;
			  $scope.matiereCourante = null;

			  $scope.global_stats    = { filled: 0,
						     validated: 0 };

			  $scope.pieChart = { options: $rootScope.globalPieChartOptions,
					      data: [ { color : $rootScope.theme.validated.base,
							value: 0 },
						      { color : $rootScope.theme.filled.base,
							value: 0 } ],
					      populate: function( data ) {
						  $scope.pieChart.data[0].value = data.validated;
						  $scope.pieChart.data[1].value = data.filled - data.validated;
					      } };

			  $scope.monthlyLineChart = { options: $rootScope.globalLineChartOptions,
						      data: { labels: $rootScope.mois,
							      datasets: [
								  // 0: saisies totales
								  { fillColor : $rootScope.theme.filled.base,
								    pointColor : $rootScope.theme.filled.base,
								    strokeColor : $rootScope.theme.filled.stroke,
								    pointStrokeColor : $rootScope.theme.filled.stroke,
								    data: []
								  },
								  // 1: saisies validées
								  { fillColor : $rootScope.theme.validated.base,
								    pointColor : $rootScope.theme.validated.base,
								    strokeColor : $rootScope.theme.validated.stroke,
								    pointStrokeColor : $rootScope.theme.validated.stroke,
								    data: []
								  } ] },
						      populate: function( data ) {
							  var monthlyLineChart_data = data.reduce( function( monthly_stats, regroupement ) {
							      _(regroupement.mensuel.filled.length).times( function( i ) {
								  monthly_stats.filled[i] += regroupement.mensuel.filled[i];
								  monthly_stats.validated[i] += regroupement.mensuel.validated[i];
							      });
							      return monthly_stats;
							  }, { filled: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
							       validated:  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] });

							  $scope.monthlyLineChart.data.datasets[0].data = monthlyLineChart_data.filled;
							  $scope.monthlyLineChart.data.datasets[1].data = monthlyLineChart_data.validated;
						      } };

			  $scope.individualCharts = { classes: [],
						      populate: function( data, classes ) {
							  $scope.individualCharts.classes = _.chain(data)
							      .map( function( regroupement ) {
								  return { libelle: classes[ regroupement.regroupement_id ],
									   pieChart: { options: $rootScope.globalPieChartOptions,
										       data: [ { color : $rootScope.theme.validated.base,
												 value: regroupement.validated },
											       { color : $rootScope.theme.filled.base,
												 value: regroupement.filled - regroupement.validated } ] } };
							      })
							      .reject( function( classe ) {
								  return _(classe.pieChart.data).reduce(function( useless, slice ) {
								      return useless && slice.value === 0;
								  }, true);
							      } )
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

			  $scope.extract_classes_promises = function( data ) {
			      return _.chain( data )
				  .pluck( 'regroupement_id' )
				  .map( function( regroupement_id ) {
				      return Annuaire.get_regroupement( regroupement_id );
				  })
				  .value();
			  };

			  $scope.process_data = function(  ) {
			      if ( $scope.raw_data.length > 0 ) {
				  $scope.displayed_data = $scope.raw_data;

				  // Filtrage par classe
				  if ( $scope.classe != null ) {
				      // .invert() suppose que les valeurs sont uniques
				      var id = _($scope.classes).invert()[$scope.classe];
				      $scope.displayed_data = _($scope.displayed_data).filter( function( r ) {
					  return r.regroupement_id == id;
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
				  $scope.monthlyLineChart.populate( $scope.displayed_data );
			      }
			  };

			  API.query_classes( { uai: current_user['profil_actif']['uai'] } ).then( function( response ) {
			      $scope.raw_data = response;

			      $scope.empty = _($scope.raw_data[ 0 ]).size() == 0;

			      if ( ! $scope.empty ) {
				  // Extraction des matières
				  $scope.matieres = $scope.extract_matieres( $scope.raw_data );

				  // Extraction des classes
				  $q.all( $scope.extract_classes_promises( $scope.raw_data ) )
				      .then( function( classes ) {
					  _(classes).each(function( classe ) {
					      $scope.classes[classe.id] = classe.libelle !== null ? classe.libelle : classe.libelle_aaf;
					  });
					  $scope.process_data();
				      });
			      }
			  });
		      } );
		  } ] );
