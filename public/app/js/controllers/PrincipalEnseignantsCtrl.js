'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('PrincipalEnseignantsCtrl',
                [ '$scope', '$locale', '$q', 'API', 'Annuaire', 'current_user', 'PIECHART_DEFINITION',
                  function( $scope, $locale, $q, API, Annuaire, current_user, PIECHART_DEFINITION ) {
                      $scope.scope = $scope;
                      // $scope.annee = _($locale.DATETIME_FORMATS.MONTH).toArray();
                      // $scope.selected_mois = null;
                      $scope.regroupements = [ ];

                      $scope.select_all_regroupements = function() {
                          $scope.selected_regroupements = $scope.regroupements;
                          $scope.filter_data();
                      };

                      $scope.select_no_regroupements = function() {
                          $scope.selected_regroupements = [];
                          $scope.filter_data();
                      };

                      var htmlify_classes_list = function( classes ) {
                          return '<p>Classes : <ul><li>' + _(classes).map( function( classe ) { return classe.classe_libelle; } ).join( '</li><li>' ) + '</li></ul></p>';
                      };

                      var htmlify_matieres_list = function( matieres ) {
                          return '<p>Matières : <ul><li>' + matieres.join( '</li><li>' ) + '</li></ul></p>';
                      };

                      $scope.filter_data = function(  ) {
                          _($scope.individualCharts.enseignants)
                              .each( function( chart ) {
                                  chart.display = !_.chain(chart.enseignant.details.classes)
                                      .pluck( 'classe_id' )
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
                                            html_classes: htmlify_classes_list( enseignant.classes ),
                                            html_matieres: htmlify_matieres_list( enseignant.matieres ),
                                            pieChart: angular.copy( PIECHART_DEFINITION ) };

                              chart.pieChart.data = [ { label: 'visas',
                                                        value: enseignant.validated },
                                                      { label: 'saisies',
                                                        value: enseignant.filled - enseignant.validated } ];

                              $scope.individualCharts.enseignants.push( chart );
                          }
                      };

                      // Récupération et consommation des données
                      API.query_enseignants( { uai: current_user.profil_actif.etablissement_code_uai } )
                          .$promise.then( function success( response ) {
                              $scope.selected_regroupements = [];
                              $scope.raw_data = _(response).reject( function( enseignant ) {
                                  return enseignant.enseignant_id === '';
                              });

                              _($scope.raw_data).each( function( enseignant ) {
                                  Annuaire.get_user( enseignant.enseignant_id ).$promise
                                      .then( function( enseignant_annuaire ) {
                                          enseignant.details = enseignant_annuaire;

                                          enseignant.matieres = _.chain(enseignant_annuaire.classes)
                                              .pluck( 'matiere_libelle' )
                                              .uniq()
                                              .compact()
                                              .value();

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

                                          $scope.regroupements = $scope.regroupements.concat( _(enseignant_annuaire.classes)
                                                                                              .map( function( regroupement ) {
                                                                                                  return { id: regroupement.classe_id,
                                                                                                           libelle: regroupement.classe_libelle,
                                                                                                           type: 'classe' };
                                                                                              } ) );
                                          $scope.regroupements = $scope.regroupements.concat( _(enseignant_annuaire.groupes_eleves)
                                                                                              .map( function( regroupement ) {
                                                                                                  return { id: regroupement.groupe_id,
                                                                                                           libelle: regroupement.groupe_libelle,
                                                                                                           type: 'groupe' };
                                                                                              } ) );

                                          $scope.regroupements = _($scope.regroupements).uniq( function( regroupement ) { return regroupement.id; } );
                                          $scope.selected_regroupements = $scope.regroupements;

                                          $scope.individualCharts.add( enseignant );
                                      } );
                              } );
                          } );

                      angular.element('#ui-view-content').after( current_user.marqueur_xiti );
                  } ] );
