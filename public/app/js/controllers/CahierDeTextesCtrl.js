'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('CahierDeTextesCtrl',
                [ '$scope', '$sce', '$q', '$state', '$stateParams', 'moment',
                  'APP_PATH', 'DOCS_URL', 'API', 'EmploisDuTemps', 'current_user', 'PopupsCreneau', 'CreneauxEmploiDuTemps', 'Utils',
                  function ( $scope, $sce, $q, $state, $stateParams, moment,
                             APP_PATH, DOCS_URL, API, EmploisDuTemps, current_user, PopupsCreneau, CreneauxEmploiDuTemps, Utils ) {
                      var first_load = true;
                      var changing_period_offset = false;

                      $scope.current_user = current_user;

                      var matieres = [];
                      var matieres_enseignees = [];
                      var popup_ouverte = false;
                      $scope.scope = $scope;
                      $scope.selected_creneau_vide = null;
                      $scope.complet = false;

                      $scope.update_regroupements_in_url = function() {
                          $stateParams.regroupements = _($scope.selected_regroupements).pluck('libelle');
                          $state.go( $state.current, $stateParams, { notify: false, reload: false } );
                      };

                      $scope.select_all_regroupements = function() {
                          $scope.selected_regroupements = $scope.current_user.profil_actif.regroupements;
                      };

                      $scope.select_no_regroupements = function() {
                          $scope.selected_regroupements = [];
                      };
                      $scope.select_all_regroupements();

                      var filter_creneaux_avec_saisies = function( raw_data ) {
                          return _.chain(raw_data)
                              .filter( function( creneau ) {
                                  return creneau.enseignant_id === $scope.current_user.uid;
                              } )
                              .reject( function( creneau ) {
                                  return _(creneau.cours).isEmpty() && _(creneau.devoirs).isEmpty();
                              })
                              .map( function( creneau ) {
                                  creneau.devoirs.ouvert = true;
                                  return creneau;
                              })
                              .value();
                      };
                      var filter_creneaux_vides = function( raw_data ) {
                          return _.chain(raw_data)
                              .filter( function( creneau ) {
                                  return creneau.enseignant_id === $scope.current_user.uid;
                              } )
                              .filter( function( creneau ) {
                                  return _(creneau.cours).isEmpty();
                              })
                              .value();
                      };

                      var list_matieres = function(raw_data) {
                          return _.chain(raw_data)
                              .pluck('matiere_id')
                              .uniq()
                              .compact()
                              .reject( function( id ) { return id === 'undefined'; } )
                              .map(function(matiere_id) {
                                  return [ matiere_id, _($scope.current_user.profil_actif.matieres).findWhere({ id: matiere_id }) ];
                              })
                              .object()
                              .value();
                      };

                      $scope.period_offset = $scope.current_user.date ? moment.duration( moment() - moment( $scope.current_user.date ) ).months() : 0;

                      // $scope.retrieve_data() when the value of week_offset changes
                      // n.b.: triggered when week_offset is initialized above
                      var nb_mois_depuis_septembre = Math.abs( 9 - ( moment().month() + 1 ) );
                      $scope.period_offsets_list = _.range( nb_mois_depuis_septembre,
                                                            ( 10 - nb_mois_depuis_septembre ) * -1,
                                                            -1 )
                          .map( function( offset ) {
                              return { offset: offset,
                                       label: offset == 0 ? 'ce mois' : moment().add( offset * -1, 'months' ).fromNow() };
                          } );
                      $scope.period_offsets_list.push( { offset: 9999,
                                                         label: 'année complète'} );

                      $scope.incr_offset = function() {
                          $scope.period_offset++;
                      };
                      $scope.decr_offset = function() {
                          $scope.period_offset--;
                      };
                      $scope.reset_offset = function() {
                          $scope.period_offset = 0;
                      };

                      $scope.retrieve_data = function() {
                          changing_period_offset = true;
                          var now = moment();

                          if ( $scope.complet ) {
                              $scope.from_date = moment();
                              $scope.to_date = moment();
                              if ( now.month() + 1 > 8 ) {
                                  $scope.from_date.set( 'year', now.year() );
                                  $scope.to_date.set( 'year', now.year() + 1 );
                              } else {
                                  $scope.from_date.set( 'year', now.year() - 1);
                                  $scope.to_date.set( 'year', now.year() );
                              }
                              $scope.from_date.set( 'month', 8 );
                              $scope.from_date.set( 'date', 1 );
                              $scope.to_date.set( 'month', 7 );
                              $scope.to_date.set( 'date', 1 );

                              $scope.from_date = $scope.from_date.toDate();
                              $scope.to_date = $scope.to_date.toDate();
                          } else {
                              if ( first_load && moment( $stateParams.date ).isValid() ) {
                                  console.log('using date from $stateParams')
                                  console.log($stateParams.date)
                                  if ( moment( $stateParams.date ).isBefore( Utils.school_year_start() ) ) {
                                      $stateParams.date = Utils.school_year_start();
                                  } else if ( moment( $stateParams.date ).isAfter( Utils.school_year_end() ) ) {
                                      $stateParams.date = Utils.school_year_end();
                                  }

                                  $scope.current_user.date = moment( $stateParams.date ).toDate();

                                  $scope.period_offset = moment.duration( now - $scope.current_user.date ).months() - 1;
                              } else {
                                  $scope.current_user.date = moment().subtract( $scope.period_offset, 'months' ).toDate();
                              }

                              $scope.from_date = moment( $scope.current_user.date ).subtract( 2, 'weeks' ).startOf( 'week' ).toDate();
                              $scope.to_date = moment( $scope.current_user.date ).add( 2, 'weeks' ).endOf( 'week' ).toDate();
                          }

                          $stateParams.date = $scope.from_date.toISOString().split('T')[0];
                          $state.go( $state.current, $stateParams, { notify: false, reload: false } );

                          EmploisDuTemps.query( { debut: $scope.from_date,
                                                  fin: $scope.to_date,
                                                  uai: $scope.current_user.profil_actif.etablissement_code_uai } )
                              .$promise
                              .then( function success( response ) {
                                  $scope.raw_data = response;
                                  matieres = list_matieres( $scope.raw_data );

                                  _($scope.raw_data).each( function( creneau ) {
                                      creneau.matiere = _($scope.current_user.profil_actif.matieres).findWhere({ id: creneau.matiere_id });
                                      creneau.regroupement = _($scope.current_user.profil_actif.regroupements).findWhere({ id: parseInt( creneau.regroupement_id ) });
                                  });

                                  $scope.creneaux_vides = filter_creneaux_vides( $scope.raw_data );

                                  $scope.creneaux_saisies = filter_creneaux_avec_saisies( $scope.raw_data );
                                  _($scope.creneaux_saisies).each( function( creneau ) {
                                      if ( !_(creneau.cours).isNull() ) {
                                          _(creneau.cours.ressources).each( function( ressource ) {
                                              ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
                                          } );
                                      }
                                      _(creneau.devoirs).each( function( devoir ) {
                                          _(devoir.ressources).each( function( ressource ) {
                                              ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
                                          } );
                                      } );
                                  } );

                                  $scope.selected_creneau_vide = null;
                              });

                          first_load = false;
                          changing_period_offset = false;
                      };
                      $scope.popup_callback = $scope.retrieve_data;

                      $scope.edition_creneau = function ( event ) {
                          CreneauxEmploiDuTemps.get( { id: event.creneau_emploi_du_temps_id } )
                              .$promise
                              .then( function( creneau_selectionne ) {
                                  creneau_selectionne.dirty = false;
                                  creneau_selectionne.en_creation = false;
                                  creneau_selectionne.heure_debut = new Date( event.start );
                                  creneau_selectionne.heure_fin = new Date( event.end );
                                  creneau_selectionne.regroupement_id = event.regroupement_id;

                                  PopupsCreneau.edition( $scope.raw_data,
                                                         matieres_enseignees, $scope.current_user.profil_actif.regroupements,
                                                         creneau_selectionne, event.cours, event.devoirs,
                                                         $scope.popup_callback, popup_ouverte );
                              } );
                      };
                      matieres_enseignees = $scope.current_user.profil_actif.matieres;

                      $scope.$watch( 'period_offset', function() {
                          if ( !changing_period_offset ) {
                              $scope.complet = $scope.period_offset == 9999;
                              $scope.retrieve_data();
                          }
                      } );
                  } ] );
