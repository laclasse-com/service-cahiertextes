'use strict';

angular.module('cahierDeTexteApp')
    .controller('FooterCtrl',
		[ '$scope', '$state', 'VERSION', 'User',
		  function ( $scope, $state, VERSION, User ) {
		      $scope.version = VERSION;

		      User.get_user().then( function( response ) {
			  $scope.current_user = response.data;

			  $scope.reload = function() {
			      $state.reload();
			  };
		      } );
		  } ] );
