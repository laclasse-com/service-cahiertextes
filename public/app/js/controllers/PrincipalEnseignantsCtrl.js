'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('PrincipalEnseignantsCtrl',
                [ '$scope', '$locale', '$q', 'API', 'Annuaire', 'current_user', 'PIECHART_DEFINITION',
                  function( $scope, $locale, $q, API, Annuaire, current_user, PIECHART_DEFINITION ) {
                      $scope.scope = $scope;
                      $scope.regroupements = [ ];

                      $scope.select_all_regroupements = function() {
                          $scope.selected_regroupements = $scope.regroupements;
                          $scope.filter_data();
                      };

                      $scope.select_no_regroupements = function() {
                          $scope.selected_regroupements = [];
                          $scope.filter_data();
                      };

                      $scope.filter_data = function(  ) {
                          _($scope.individualCharts.enseignants)
                              .each( function( chart ) {
                                  chart.display = !_.chain(chart.enseignant.details.regroupements)
                                      .pluck( 'id' )
                                      .intersection( _($scope.selected_regroupements).pluck( 'id' ) )
                                      .isEmpty()
                                      .value();
                              } );
                      };

                      $scope.individualCharts = {
                          enseignants: [ ],
                          add: function( enseignant ) {
                              var chart = { enseignant: enseignant,
                                            display: true,
                                            pieChart: angular.copy( PIECHART_DEFINITION ) };

                              chart.pieChart.data = [ { label: 'saisies',
                                                        value: enseignant.filled - enseignant.validated },
                                                      { label: 'visas',
                                                        value: enseignant.validated } ];

                              $scope.individualCharts.enseignants.push( chart );
                          }
                      };

                      // Récupération et consommation des données
                      API.query_enseignants( { uai: current_user.profil_actif.structure_id } )
                          .$promise.then( function success( response ) {
                              $scope.selected_regroupements = [];
                              $scope.raw_data = _(response).reject( function( enseignant ) {
                                  return enseignant.enseignant_id === '';
                              });

                              Annuaire.get_users( _($scope.raw_data).pluck( 'enseignant_id' ) )
                                  .then( function( response ) {
                                      var enseignants_details = _(response.data).indexBy( 'id' );

                                      $scope.regroupements = _.chain(response)
                                          .pluck( 'regroupements' )
                                          .flatten()
                                          .where({ etablissement_code: current_user.profil_actif.structure_id })
                                          .map( function( regroupement ) {
                                              return { id: regroupement.id,
                                                       libelle: regroupement.libelle,
                                                       type: regroupement.type == 'CLS' ? 'classe' : 'groupe' };
                                          } )
                                          .uniq( function( regroupement ) { return regroupement.id; } )
                                          .value();

                                      $scope.selected_regroupements = $scope.regroupements;

                                      _($scope.raw_data).each( function( enseignant ) {
                                          enseignant.details = enseignants_details[ enseignant.enseignant_id ];

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

                                          $scope.individualCharts.add( enseignant );
                                      } );
                                  } );



                          } );
                  } ] );
