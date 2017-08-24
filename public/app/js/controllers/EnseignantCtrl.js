'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('EnseignantCtrl',
                [ '$scope', '$state', 'current_user',
                  function ( $scope, $state, current_user ) {
                      $scope.tabs = [ { heading: 'Emploi du temps',
                                        uisref: 'enseignant.emploi_du_temps',
                                        css_class: 'glyphicon glyphicon-calendar',
                                        active: true },
                                      { heading: 'Statistiques',
                                        uisref: 'enseignant.stats',
                                        css_class: 'glyphicon glyphicon-stats',
                                        active: false } ];

                      if ( current_user.profil_actif.admin ) {
                          $scope.tabs.push( { heading: 'Import Pronote',
                                              uisref: 'enseignant.import',
                                              css_class: 'glyphicon glyphicon-import',
                                              active: false } );
                      }

                      _($scope.tabs).each( function( tab ) {
                          tab.active = tab.uisref == $state.current.name;
                      } );

                      $scope.set_active_tab = function( uisref ) {
                          _($scope.tabs).each( function( tab ) {
                              tab.active = tab.uisref == uisref;
                          } );
                      };

                      $scope.current_user = current_user;
                  } ] );
