'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('EleveDevoirsCtrl',
                [ '$scope', '$sce', '$timeout', 'toastr', '$state', '$stateParams', 'moment',
                  'APP_PATH', 'URL_DOCS', 'API', 'Annuaire', 'Devoirs', 'Cours', 'CreneauxEmploiDuTemps',
                  'current_user',
                  function( $scope, $sce, $timeout, toastr, $state, $stateParams, moment,
                            APP_PATH, URL_DOCS, API, Annuaire, Devoirs, Cours, CreneauxEmploiDuTemps,
                            current_user ) {
                      // popup d'affichage des détails
                      $scope.affiche_faits = false;
                      $scope.tri_ascendant = true;
                      $scope.popup_ouverte = false;
                      $scope.matiere_selected = null;

                      $scope.current_user = current_user;

                      var getCours = _.memoize( function( id ) {
                          return Cours.get({ id: id });
                      } );

                      var getCreneauxEmploiDuTemps = _.memoize( function( id ) {
                          return CreneauxEmploiDuTemps.get({ id: id });
                      } );

                      var retrieve_data = function() {
                          $scope.from_date = moment().subtract( $scope.period_offset, 'months' ).subtract( 2, 'weeks' ).toDate();
                          $scope.to_date = moment().subtract( $scope.period_offset, 'months' ).add( 2, 'weeks' ).toDate();

                          $stateParams.from = $scope.from_date.toISOString().split('T')[0];
                          $stateParams.to = $scope.to_date.toISOString().split('T')[0];
                          $state.go( $state.current, $stateParams, { notify: false, reload: false } );

                          API.query_devoirs({ 'date_due<': $scope.from_date,
                                              'date_due>': $scope.to_date,
                                              uid: $scope.current_user.profil_actif.type === 'TUT' ? $scope.current_user.enfant_actif.child_id : null })
                              .$promise.then(function( response ) {
                                  $scope.matieres = {};

                                  $scope.all_devoirs = _(response).map( function( devoir ) {
                                      devoir.cours = getCours( devoir.cours_id );
                                      devoir.creneau_emploi_du_temps = getCreneauxEmploiDuTemps( devoir.creneau_emploi_du_temps_id );

                                      devoir.creneau_emploi_du_temps.$promise
                                          .then( function() {
                                              Annuaire.get_subject( devoir.creneau_emploi_du_temps.matiere_id )
                                                  .then( function( response ) {
                                                      devoir.matiere = response.data;
                                                      $scope.matieres[ devoir.matiere.id ] = devoir.matiere;
                                                  } );
                                          } );

                                      _(devoir.ressources).each( function( ressource ) {
                                          ressource.url = $sce.trustAsResourceUrl( URL_DOCS + '/api/connector?cmd=file&target=' + ressource.hash );
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
