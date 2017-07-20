'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('EleveDevoirsCtrl',
                [ '$scope', '$sce', '$timeout', 'toastr', '$state', '$stateParams', 'moment',
                  'APP_PATH', 'DOCS_URL', 'API', 'Annuaire', 'Devoirs', 'Cours', 'CreneauxEmploiDuTemps', 'PopupsCreneau',
                  'current_user',
                  function( $scope, $sce, $timeout, toastr, $state, $stateParams, moment,
                            APP_PATH, DOCS_URL, API, Annuaire, Devoirs, Cours, CreneauxEmploiDuTemps, PopupsCreneau,
                            current_user ) {
                      // popup d'affichage des détails
                      $scope.affiche_faits = false;
                      $scope.tri_ascendant = true;
                      $scope.popup_ouverte = false;
                      $scope.matiere_selected = null;
                      var popup_ouverte = false;
                      var popup_callback = function() {};

                      $scope.popup_display = function( devoir ) {
                          PopupsCreneau.display( devoir.matiere.name,
                                                 devoir.cours,
                                                 [ devoir ],
                                                 popup_callback,
                                                 popup_ouverte );
                      };

                      $scope.current_user = current_user;

                      var retrieve_data = function() {
                          $scope.from_date = moment().subtract( $scope.period_offset, 'months' ).subtract( 2, 'weeks' ).toDate();
                          $scope.to_date = moment().subtract( $scope.period_offset, 'months' ).add( 2, 'weeks' ).toDate();

                          $stateParams.from = $scope.from_date.toISOString().split('T')[0];
                          $stateParams.to = $scope.to_date.toISOString().split('T')[0];
                          $state.go( $state.current, $stateParams, { notify: false, reload: false } );

                          API.query_devoirs({ debut: $scope.from_date,
                                              fin: $scope.to_date,
                                              uid: $scope.current_user.profil_actif.type === 'TUT' ? $scope.current_user.enfant_actif.child_id : null })
                              .$promise.then(function( response ) {
                                  $scope.matieres = {};

                                  $scope.all_devoirs = _(response).map( function( devoir ) {
                                      $scope.matieres[ devoir.creneau_emploi_du_temps.matiere_id ] = _($scope.current_user.profil_actif.matieres).findWhere({ id: devoir.creneau_emploi_du_temps.matiere_id });
                                      devoir.matiere = $scope.matieres[ devoir.creneau_emploi_du_temps.matiere_id ];

                                      _(devoir.ressources).each( function( ressource ) {
                                          ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
                                      } );

                                      return devoir;
                                  });
                                  $scope.filter_data( $scope.matiere_selected );
                              });
                      };

                      $scope.filter_data = function( matiere ) {
                          if ( _(matiere).isNull() ) {
                              $scope.devoirs = $scope.all_devoirs;
                              $stateParams.matiere = null;
                          } else {
                              $scope.devoirs = _($scope.all_devoirs).select( function( devoir ) {
                                  return devoir.creneau_emploi_du_temps.matiere_id == matiere.id;
                              } );
                              $stateParams.matiere = matiere.name;
                          }
                          $state.go( $state.current, $stateParams, { notify: false, reload: false } );
                      };

                      $scope.period_offset = 0;

                      // retrieve_data() when the value of week_offset changes
                      // n.b.: triggered when period_offset is initialized above
                      var nb_mois_depuis_septembre = Math.abs( 9 - ( moment().month() + 1 ) );
                      $scope.period_offsets_list = _.range( nb_mois_depuis_septembre, ( 10 - nb_mois_depuis_septembre ) * -1, -1 )
                          .map( function( offset ) {
                              return { offset: offset,
                                       label: offset == 0 ? 'ce mois' : moment().add( offset * -1, 'months' ).fromNow() };
                          } );

                      $scope.$watch( 'period_offset', function() {
                          retrieve_data();
                      } );

                      $scope.incr_offset = function() { $scope.period_offset++; };
                      $scope.decr_offset = function() { $scope.period_offset--; };
                      $scope.reset_offset = function() { $scope.period_offset = 0; };
                  } ] );
