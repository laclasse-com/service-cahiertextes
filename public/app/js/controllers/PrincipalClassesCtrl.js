'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('PrincipalClassesCtrl',
                [ '$scope', '$locale', 'API', 'Annuaire', 'CreneauxEmploiDuTemps', 'current_user', 'PIECHART_DEFINITION', 'MULTIBARCHART_DEFINITION',
                  function ( $scope, $locale, API, Annuaire, CreneauxEmploiDuTemps, current_user, PIECHART_DEFINITION, MULTIBARCHART_DEFINITION ) {
                      $scope.empty = false;
                      $scope.scope = $scope;

                      $scope.raw_data    = [];
                      $scope.displayed_data  = [];
                      $scope.classes     = [];
                      $scope.matieres    = [];
                      $scope.annee = _($locale.DATETIME_FORMATS.MONTH).toArray();

                      $scope.selected_mois       = null;
                      $scope.selected_matiere = null;

                      $scope.delete_creneaux = function( creneaux_id ) {
                          var end_of_last_august = moment().endOf('month');
                          while ( end_of_last_august.month() !== 7 ) {
                              end_of_last_august.subtract( 1, 'month' );
                          }
                          end_of_last_august = end_of_last_august.toDate();

                          swal( { title: 'ATTENTION',
                                  text: 'Ceci supprimera les ' + creneaux_id.length + 'créneaux',
                                  type: 'warning',
                                  showCancelButton: true,
                                  confirmButtonColor: '#ff6b55',
                                  confirmButtonText: 'Confirmer',
                                  cancelButtonText: 'Annuler' },
                                function () {
                                    _(creneaux_id).each( function( id ) {
                                        CreneauxEmploiDuTemps.delete( { id: id,
                                                                        date_creneau: end_of_last_august } );
                                    } );
                                } );
                      };

                      $scope.select_all_regroupements = function() {
                          $scope.selected_regroupements = $scope.classes;
                          $scope.process_data();
                      };

                      $scope.select_no_regroupements = function() {
                          $scope.selected_regroupements = [];
                          $scope.process_data();
                      };

                      $scope.global_stats    = { filled: 0,
                                                 validated: 0 };

                      $scope.pieChart = angular.copy( PIECHART_DEFINITION );
                      $scope.multiBarChart = angular.copy( MULTIBARCHART_DEFINITION );
                      $scope.pieChart.populate = function( data ) {
                          $scope.pieChart.data = [ { label: 'saisies',
                                                     value: data.filled - data.validated },
                                                   { label: 'visas',
                                                     value: data.validated } ];
                      };
                      $scope.multiBarChart.populate = function( data ) {
                          var sort_by_index = function( a, b ) { return a.index > b.index; };

                          var data_bootstrap = _($scope.annee).map( function( mois ) {
                              return { key: mois,
                                       y : 0 };
                          } );

                          var multiBarChart_data = data.reduce( function( monthly_stats, regroupement ) {
                              _(12).times( function( i ) {
                                  var index = i > 7 ? i - 8 : i + 4;
                                  monthly_stats.filled[ i ].index = index;
                                  monthly_stats.filled[ i ].x = $scope.annee[ i ];
                                  monthly_stats.filled[ i ].y += regroupement.mensuel.filled[ i ];

                                  monthly_stats.validated[ i ].index = index;
                                  monthly_stats.validated[ i ].x = $scope.annee[ i ];
                                  monthly_stats.validated[ i ].y += regroupement.mensuel.validated[ i ];
                              } );
                              return monthly_stats;
                          }, { filled: angular.copy( data_bootstrap ),
                               validated: angular.copy( data_bootstrap ) } );


                          $scope.multiBarChart.data = [ { key: 'saisies',
                                                          values: multiBarChart_data.filled.sort( sort_by_index ) },
                                                        { key: 'visas',
                                                          values: multiBarChart_data.validated.sort( sort_by_index ) } ];
                      };

                      $scope.individualCharts = { classes: [],
                                                  populate: function( data, classes ) {
                                                      var hashed_classes = _.chain(classes).map( function(c) { return [ c.id, c ]; } ).object().value();
                                                      $scope.individualCharts.classes = _(data)
                                                          .map( function( regroupement ) {
                                                              var individualChart = { classe: regroupement,
                                                                                      regroupement: hashed_classes[ regroupement.regroupement_id ],
                                                                                      pieChart: angular.copy( PIECHART_DEFINITION ) };
                                                              individualChart.pieChart.data = [ { label: 'saisies',
                                                                                                  value: regroupement.filled - regroupement.validated },
                                                                                                { label: 'visas',
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
                                  var matiere = _(current_user.profil_actif.matieres).findWhere({ id: matiere_id });
                                  if ( _(matiere).isUndefined() ) {
                                      matiere = Annuaire.get_matiere( matiere_id );
                                  }

                                  return matiere;
                              })
                              .value();
                      };

                      $scope.extract_classes = function( data ) {
                          return _.chain( data )
                              .pluck( 'regroupement_id' )
                              .map(function( regroupement_id ) {
                                  regroupement_id = parseInt( regroupement_id );
                                  var regroupement = _(current_user.profil_actif.regroupements).findWhere({ id: regroupement_id });
                                  if ( _(regroupement).isUndefined() ) {
                                      regroupement = Annuaire.get_regroupement( regroupement_id );
                                  }

                                  return regroupement;
                              })
                              .value();
                      };

                      $scope.process_data = function(  ) {
                          if ( $scope.raw_data.length > 0 ) {
                              $scope.displayed_data = $scope.raw_data;

                              $scope.displayed_data = _($scope.displayed_data).select( function( regroupement ) {
                                  return _.chain($scope.selected_regroupements)
                                      .pluck( 'id' )
                                      .contains( parseInt(regroupement.regroupement_id) )
                                      .value();
                              } );

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
                              $scope.multiBarChart.populate( $scope.displayed_data );
                          }
                      };

                      API.query_classes( { uai: current_user.profil_actif.etablissement_code_uai } )
                          .$promise.then( function( response ) {
                              $scope.raw_data = response;

                              $scope.creneaux_emploi_du_temps = _(response).reduce( function( memo, regroupement ) {
                                  memo.vides = memo.vides.concat( regroupement.creneaux_emploi_du_temps.vides );
                                  memo.pleins = memo.pleins.concat( regroupement.creneaux_emploi_du_temps.pleins );

                                  return memo;
                              },
                                                                                    { vides: [],
                                                                                      pleins: [] } );

                              $scope.empty = _($scope.raw_data[ 0 ]).size() == 0;

                              if ( ! $scope.empty ) {
                                  // Extraction des matières
                                  $scope.matieres = $scope.extract_matieres( $scope.raw_data );

                                  // Extraction des classes
                                  $scope.classes = $scope.extract_classes( $scope.raw_data );

                                  $scope.select_all_regroupements();
                                  //$scope.process_data();
                              }
                          });
                  } ] );
