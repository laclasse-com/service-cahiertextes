'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .controller( 'FooterCtrl',
  [ '$scope', '$state', '$stateParams', '$sce', 'VERSION', 'User',
    function( $scope, $state, $stateParams, $sce, VERSION, User ) {
      $scope.version = VERSION;

      User.get_user().then( function( response ) {
        $scope.current_user = response.data;

        $scope.save_and_reload = function() {
          User.update_parameters( $scope.current_user.parametrage_cahier_de_textes )
            .then( function() {
              $state.transitionTo( $state.current, $stateParams, { reload: true, inherit: true, notify: true } );
            } );
        };
      } );
    }] );
