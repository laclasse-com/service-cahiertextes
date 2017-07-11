'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('PrincipalRegroupementsCtrl',
                [ '$scope', '$locale', '$q', 'API', 'Annuaire', 'CreneauxEmploiDuTemps', 'current_user', 'PIECHART_DEFINITION', 'MULTIBARCHART_DEFINITION',
                  function ( $scope, $locale, $q, API, Annuaire, CreneauxEmploiDuTemps, current_user, PIECHART_DEFINITION, MULTIBARCHART_DEFINITION ) {
                      var ctrl = $scope;
                      ctrl.scope = $scope;

                      ctrl.empty = false;

                      ctrl.raw_data    = [];
                      ctrl.displayed_data  = [];
                      ctrl.regroupements     = [];
                      ctrl.matieres    = [];
                      ctrl.annee = _($locale.DATETIME_FORMATS.MONTH).toArray();

                      ctrl.selected_mois       = null;
                      ctrl.selected_matiere = null;

                      ctrl.select_all_regroupements = function() {
                          ctrl.selected_regroupements = ctrl.regroupements;
                          ctrl.process_data();
                      };

                      ctrl.select_no_regroupements = function() {
                          ctrl.selected_regroupements = [];
                          ctrl.process_data();
                      };

                      ctrl.global_stats    = { filled: 0,
                                                 validated: 0 };

                      ctrl.pieChart = angular.copy( PIECHART_DEFINITION );
                      ctrl.multiBarChart = angular.copy( MULTIBARCHART_DEFINITION );
                      ctrl.pieChart.populate = function( data ) {
                          ctrl.pieChart.data = [ { label: 'saisies',
                                                     value: data.filled - data.validated },
                                                   { label: 'visas',
                                                     value: data.validated } ];
                      };
                      ctrl.multiBarChart.populate = function( data ) {
                          var sort_by_index = function( a, b ) { return a.index > b.index; };

                          var data_bootstrap = _(ctrl.annee).map( function( mois ) {
                              return { key: mois,
                                       y : 0 };
                          } );

                          var multiBarChart_data = data.reduce( function( monthly_stats, regroupement ) {
                              _(12).times( function( i ) {
                                  var index = i > 7 ? i - 8 : i + 4;
                                  monthly_stats.filled[ i ].index = index;
                                  monthly_stats.filled[ i ].x = ctrl.annee[ i ];
                                  monthly_stats.filled[ i ].y += regroupement.mensuel.filled[ i ];

                                  monthly_stats.validated[ i ].index = index;
                                  monthly_stats.validated[ i ].x = ctrl.annee[ i ];
                                  monthly_stats.validated[ i ].y += regroupement.mensuel.validated[ i ];
                              } );
                              return monthly_stats;
                          }, { filled: angular.copy( data_bootstrap ),
                               validated: angular.copy( data_bootstrap ) } );


                          ctrl.multiBarChart.data = [ { key: 'saisies',
                                                          values: multiBarChart_data.filled.sort( sort_by_index ) },
                                                        { key: 'visas',
                                                          values: multiBarChart_data.validated.sort( sort_by_index ) } ];
                      };

                      ctrl.individualCharts = { regroupements: [],
                                                  populate: function( data, regroupements ) {
                                                      var hashed_regroupements = _.chain(regroupements).map( function(c) { return [ c.id, c ]; } ).object().value();
                                                      ctrl.individualCharts.regroupements = _(data)
                                                          .map( function( regroupement ) {
                                                              var individualChart = { data: regroupement,
                                                                                      regroupement: hashed_regroupements[ regroupement.regroupement_id ],
                                                                                      pieChart: angular.copy( PIECHART_DEFINITION ) };
                                                              individualChart.pieChart.data = [ { label: 'saisies',
                                                                                                  value: regroupement.filled - regroupement.validated },
                                                                                                { label: 'visas',
                                                                                                  value: regroupement.validated } ];
                                                              return individualChart;
                                                          });
                                                  } };

                      ctrl.extract_matieres = function( data ) {
                          return _.chain(data)
                              .pluck( 'matieres' )
                              .flatten()
                              .pluck( 'matiere_id' )
                              .uniq()
                              .compact()
                              .map( function( matiere_id ) {
                                  var matiere = _(current_user.profil_actif.matieres).findWhere({ id: matiere_id });
                                  if ( _(matiere).isUndefined() ) {
                                      matiere = Annuaire.get_subject( matiere_id );
                                  }

                                  return matiere;
                              })
                              .value();
                      };

                      ctrl.extract_regroupements = function( data ) {
                          return _.chain( data )
                              .pluck( 'regroupement_id' )
                              .map(function( regroupement_id ) {
                                  regroupement_id = parseInt( regroupement_id );
                                  var regroupement = _(current_user.profil_actif.regroupements).findWhere({ id: regroupement_id });
                                  if ( _(regroupement).isUndefined() ) {
                                      regroupement = Annuaire.get_group( regroupement_id );
                                  }

                                  return regroupement;
                              })
                              .sortBy( function( regroupement ) {
                                  return regroupement.type;
                              } )
                              .value();
                      };

                      ctrl.process_data = function() {
                          if ( ctrl.raw_data.length > 0 ) {
                              ctrl.displayed_data = ctrl.raw_data;

                              ctrl.displayed_data = _(ctrl.displayed_data).select( function( regroupement ) {
                                  return _.chain(ctrl.selected_regroupements)
                                      .pluck( 'id' )
                                      .contains( parseInt(regroupement.regroupement_id) )
                                      .value();
                              } );

                              // Filtrage sur une matière
                              if ( ctrl.selected_matiere != null ) {
                                  ctrl.displayed_data = ctrl.displayed_data.map( function( regroupement ) {
                                      var matieres = _(regroupement.matieres).filter( function( r ) {
                                          return r.matiere_id == ctrl.selected_matiere;
                                      });

                                      return { regroupement_id: regroupement.regroupement_id,
                                               matieres: matieres };
                                  });
                              }

                              // filtrage sur un mois
                              if ( ctrl.selected_mois != null ) {
                                  ctrl.displayed_data = ctrl.displayed_data.map( function( regroupement ) {
                                      return { regroupement_id: regroupement.regroupement_id,
                                               matieres: regroupement.matieres.map( function( matiere ) {
                                                   return { matiere_id: matiere.matiere_id,
                                                            mois: _(matiere.mois).filter( function( mois ) {
                                                                return mois.mois == ctrl.selected_mois;
                                                            }) };
                                               }) };
                                  });
                              }

                              // Calcul des statistiques mensuelles et par regroupement
                              _(ctrl.displayed_data).each( function( regroupement ) {
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

                              var global_stats = ctrl.displayed_data.reduce( function( totaux, regroupement ) {
                                  return { filled: totaux.filled + regroupement.filled,
                                           validated: totaux.validated + regroupement.validated };
                              }, { filled: 0, validated: 0 });

                              ctrl.displayed_data.filled = global_stats.filled;
                              ctrl.displayed_data.validated = global_stats.validated;

                              // consommation des données dans les graphiques
                              ctrl.individualCharts.populate( ctrl.displayed_data, ctrl.regroupements );
                              ctrl.pieChart.populate( ctrl.displayed_data );
                              ctrl.multiBarChart.populate( ctrl.displayed_data );
                          }
                      };

                      ctrl.$onInit = function() {
                          API.query_statistiques_regroupements( { uai: current_user.profil_actif.structure_id } )
                              .$promise.then( function( response ) {
                                  ctrl.raw_data = response;

                                  ctrl.creneaux_emploi_du_temps = _(ctrl.raw_data).reduce( function( memo, regroupement ) {
                                      memo.vides = memo.vides.concat( regroupement.creneaux_emploi_du_temps.vides );
                                      memo.pleins = memo.pleins.concat( regroupement.creneaux_emploi_du_temps.pleins );

                                      return memo;
                                  },
                                                                                           { vides: [],
                                                                                     pleins: [] } );

                                  ctrl.empty = _(ctrl.raw_data[ 0 ]).size() == 0;

                                  if ( ! ctrl.empty ) {
                                      ctrl.matieres = ctrl.extract_matieres( ctrl.raw_data );
                                      ctrl.regroupements = ctrl.extract_regroupements( ctrl.raw_data );

                                      ctrl.select_all_regroupements();
                                  }
                              });
                      };

                      ctrl.delete_creneaux = function( creneaux, type ) {
                          var end_of_last_august = moment().endOf('month');
                          while ( end_of_last_august.month() !== 7 ) {
                              end_of_last_august.subtract( 1, 'month' );
                          }
                          end_of_last_august = end_of_last_august.toDate();

                          swal( { title: 'ATTENTION',
                                  text: 'Ceci supprimera ' + creneaux[ type ].length + ' créneaux ' + type,
                                  type: 'warning',
                                  showLoaderOnConfirm: true,
                                  showCancelButton: true,
                                  confirmButtonColor: '#ff6b55',
                                  confirmButtonText: 'Confirmer',
                                  cancelButtonText: 'Annuler',
                                  preConfirm: function() {
                                      var bulk_package_size = 1500;
                                      var promises = [];

                                      while ( creneaux[ type ].length > 0 ) {
                                          promises.push( CreneauxEmploiDuTemps.bulk_delete( { ids: angular.toJson( creneaux[ type ].splice( 0, bulk_package_size ) ),
                                                                                              date_creneau: end_of_last_august,
                                                                                              ignore_matiere: true } ).$promise );
                                      }

                                      $q.all( promises )
                                          .then( function success( response ) {
                                              ctrl.$onInit();

                                              swal.closeModal();
                                          }, function error( response ) {
                                              swal.closeModal();
                                          } );
                                  },
                                  allowOutsideClick: false } );
                      };

                      ctrl.$onInit();
                } ] );
