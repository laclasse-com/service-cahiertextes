'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .controller( 'FooterCtrl',
  [ '$scope', '$state', '$stateParams', '$sce', 'VERSION', 'CurrentUser',
    function( $scope, $state, $stateParams, $sce, VERSION, CurrentUser ) {
      $scope.version = VERSION;

      CurrentUser.get().then( function( response ) {
        $scope.current_user = response.data;

        $scope.save_and_reload = function() {
          CurrentUser.update_parameters( $scope.current_user.parametrage_cahier_de_textes )
            .then( function() {
              $state.transitionTo( $state.current, $stateParams, { reload: true, inherit: true, notify: true } );
            } );
        };
      } );
    }] );
