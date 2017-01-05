'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('HeaderCtrl',
                [ '$scope', '$state', 'User', 'Redirection', '$sce', 'DOCS_URL',
                  function ( $scope, $state, User, Redirection, $sce, DOCS_URL ) {
                      $scope.DOCS_URL_login = $sce.trustAsResourceUrl( DOCS_URL + '/login' );
                      $scope.embedded = window != window.top;
                      User.get_user().then( function( response ) {
                          $scope.current_user = response;
                      });

                      $scope.reload = function() {
                          // Changement du profil actif dans l'annuaire
                          // Rechargement de l'application
                          Redirection.doorman( [  ] );
                      };
                  } ] );
