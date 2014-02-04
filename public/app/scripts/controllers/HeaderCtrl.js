'use strict';

angular.module('cahierDeTexteApp')
    .controller('HeaderCtrl',
		[ '$scope', '$location', 'CurrentUser',
		  function ($scope, $location, CurrentUser) {
		      CurrentUser.getCurrentUser().success( function( response ) {
			  $scope.current_user = response;
			  $scope.current_user_display = response;
		      });
		  } ] );
