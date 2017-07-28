'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('ADMCtrl',
                [ '$scope', '$state',
                  function ( $scope, $state ) {
                      $scope.tabs = [ { heading: 'Emplois du Temps',
                                        uisref: 'adm.emploi_du_temps',
                                        css_class: 'glyphicon glyphicon-calendar',
                                        active: true },
                                      { heading: 'Import Pronote',
                                        uisref: 'adm.import',
                                        css_class: 'glyphicon glyphicon-import',
                                        active: false } ];

                      _($scope.tabs).each( function( tab ) {
                          tab.active = tab.uisref == $state.current.name;
                      } );

                      $scope.set_active_tab = function( uisref ) {
                          _($scope.tabs).each( function( tab ) {
                              tab.active = tab.uisref == uisref;
                          } );
                      };
                  } ] );
