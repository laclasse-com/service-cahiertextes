'use strict';

angular.module('cahierDeTexteApp')
    .controller('HeaderCtrl',
		[ '$scope', '$location', '$state', 'User',
		  function ( $scope, $location, $state, User ) {
		      User.get_user().success( function( response ) {
			  $scope.current_user = response;
		      });

		      $scope.reload = function() {
			  $state.go($state.$current, null, { reload: true });
		      };
		  } ] );
