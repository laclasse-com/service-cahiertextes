'use strict';

angular.module('cahierDeTexteApp')
    .controller('FooterCtrl',
		[ '$scope', '$state', 'VERSION', 'User',
		  function ( $scope, $state, VERSION, User ) {
		      $scope.version = VERSION;

		      User.get_user().then( function( response ) {
			  $scope.current_user = response.data;

			  $scope.save_and_reload = function() {
			      User.update_parameters( $scope.current_user.parametrage_cahier_de_textes )
				  .success( function() {
				      $state.reload();
				  } );
			  };
		      } );
		  } ] );
