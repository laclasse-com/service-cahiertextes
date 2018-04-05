'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .controller( 'HeaderCtrl',
  [ '$scope', '$state', 'CurrentUser', 'Redirection', '$sce', 'URL_DOCS',
    function( $scope, $state, CurrentUser, Redirection, $sce, URL_DOCS ) {
      let ctrl = $scope;
      ctrl.$ctrl = ctrl;

      ctrl.load_docs = window.location.hostname !== 'localhost';

      ctrl.URL_DOCS_login = $sce.trustAsResourceUrl( `${ URL_DOCS }/login` );
      ctrl.embedded = window != window.top;
      CurrentUser.get().then( function( response ) {
        ctrl.current_user = response;
      } );

      ctrl.reload = function() {
        // Changement du profil actif dans l'annuaire
        // Rechargement de l'application
        Redirection.doorman( [] );
      };
    }] );
