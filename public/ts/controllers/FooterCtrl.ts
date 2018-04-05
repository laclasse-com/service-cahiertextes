'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .controller( 'FooterCtrl',
  [ '$scope', '$state', '$stateParams', '$sce', 'VERSION', 'CurrentUser',
    function( $scope, $state, $stateParams, $sce, VERSION, CurrentUser ) {
      let ctrl = $scope;
      ctrl.$ctrl = ctrl;

      ctrl.version = VERSION;

      CurrentUser.get().then( function( response ) {
        ctrl.current_user = response;

        ctrl.save_and_reload = function() {
          CurrentUser.update_parameters( ctrl.current_user.parametrage_cahier_de_textes )
            .then( function() {
              $state.transitionTo( $state.current, $stateParams, { reload: true, inherit: true, notify: true } );
            } );
        };
      } );
    }] );
