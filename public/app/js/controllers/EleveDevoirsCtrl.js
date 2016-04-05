'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('EleveDevoirsCtrl',
                [ '$scope', '$sce', '$timeout', 'toastr',
                  'APP_PATH', 'DOCS_URL', 'API', 'Annuaire', 'Devoirs', 'Cours', 'CreneauxEmploiDuTemps',
                  'current_user',
                  function( $scope, $sce, $timeout, toastr,
                            APP_PATH, DOCS_URL, API, Annuaire, Devoirs, Cours, CreneauxEmploiDuTemps,
                            current_user ) {
                      // popup d'affichage des détails
                      var types_de_devoir = [];
                      $scope.affiche_faits = false;
                      $scope.tri_ascendant = true;
                      $scope.popup_ouverte = false;
                      $scope.fait = function( devoir ) {
                          devoir.$fait()
                              .then( function( response ) {
                                  if ( response.fait ) {
                                      toastr.success( 'Devoir fait.',
                                                      'Bravo !' );
                                  } else {
                                      toastr.info( 'Devoir à faire',
                                                   'Encore un petit effort.' );
                                  }
                                  if ( !$scope.affiche_faits && !_(response.date_fait).isNull() ) {
                                      var date_fait_holder = response.date_fait;
                                      response.date_fait = null;

                                      $timeout( function() { response.date_fait = date_fait_holder; }, 3000 );
                                  }
                              } );
                      };

                      $scope.current_user = current_user;

                      API.query_types_de_devoir()
                          .$promise.then( function( response ) {
                              types_de_devoir = response;

                              var retrieve_data = function() {
                                  $scope.from_date = moment().subtract( $scope.period_offset, 'months' ).subtract( 2, 'weeks' ).toDate();
                                  $scope.to_date = moment().subtract( $scope.period_offset, 'months' ).add( 2, 'weeks' ).toDate();

                                  API.query_devoirs({ debut: $scope.from_date,
                                                      fin: $scope.to_date,
                                                      uid: $scope.current_user.profil_actif.profil_id == 'TUT' ? $scope.current_user.enfant_actif.enfant.id_ent : null })
                                      .$promise.then(function( response ) {
                                          $scope.matieres = {};

                                          $scope.all_devoirs = _(response).map( function( devoir ) {
                                              devoir.type_devoir = _(types_de_devoir).findWhere({id: devoir.type_devoir_id});

                                              CreneauxEmploiDuTemps.get({ id: devoir.creneau_emploi_du_temps_id })
                                                  .$promise.then( function success( response ) {
                                                      devoir.creneau_emploi_du_temps = response;
                                                      $scope.matieres[ devoir.creneau_emploi_du_temps.matiere_id ] = _($scope.current_user.profil_actif.matieres).findWhere({ id: devoir.creneau_emploi_du_temps.matiere_id });
                                                      devoir.matiere = $scope.matieres[ devoir.creneau_emploi_du_temps.matiere_id ];
                                                  });

                                              devoir.cours = _(devoir.cours_id).isNull() ? null : Cours.get({ id: devoir.cours_id });

                                              _(devoir.ressources).each( function( ressource ) {
                                                  ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
                                              } );

                                              return devoir;
                                          });
                                          $scope.devoirs = $scope.all_devoirs;
                                      });
                              };

                              $scope.filter_data = function( matiere_id ) {
                                  if ( _(matiere_id).isNull() ) {
                                      $scope.devoirs = $scope.all_devoirs;
                                  } else {
                                      $scope.devoirs = _($scope.all_devoirs).select( function( devoir ) {
                                          return devoir.creneau_emploi_du_temps.matiere_id == matiere_id;
                                      } );
                                  }
                              };

                              $scope.period_offset = 0;

                              // retrieve_data() when the value of week_offset changes
                              // n.b.: triggered when period_offset is initialized above
                              var nb_mois_depuis_septembre = Math.abs( 9 - ( moment().month() + 1 ) );
                              $scope.period_offsets_list = _.range( nb_mois_depuis_septembre,
                                                                    ( 10 - nb_mois_depuis_septembre ) * -1,
                                                                    -1 )
                                  .map( function( offset ) {
                                      return { offset: offset,
                                               label: offset == 0 ? 'ce mois' : moment().add( offset * -1, 'months' ).fromNow() };
                                  } );
                              // $scope.period_offsets_list.push( { offset: 9999,
                              //                                         label: 'année complète'} );
                              $scope.$watch( 'period_offset', function() {
                                  retrieve_data();
                              } );

                              $scope.incr_offset = function() {
                                  $scope.period_offset++;
                              };
                              $scope.decr_offset = function() {
                                  $scope.period_offset--;
                              };
                              $scope.reset_offset = function() {
                                  $scope.period_offset = 0;
                              };
                          });
                  } ] );
