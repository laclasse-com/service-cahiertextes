'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .controller( 'HeaderCtrl',
  [ '$scope', '$state', 'CurrentUser', 'Redirection', '$sce', 'URL_DOCS',
    function( $scope, $state, CurrentUser, Redirection, $sce, URL_DOCS ) {
      $scope.load_docs = window.location.hostname !== 'localhost';

      $scope.URL_DOCS_login = $sce.trustAsResourceUrl( `${ URL_DOCS }/login` );
      $scope.embedded = window != window.top;
      CurrentUser.get().then( function( response ) {
        $scope.current_user = response.data;
      } );

      $scope.reload = function() {
        // Changement du profil actif dans l'annuaire
        // Rechargement de l'application
        Redirection.doorman( [] );
      };
    }] );
