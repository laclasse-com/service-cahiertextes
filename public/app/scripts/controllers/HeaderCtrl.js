'use strict';

angular.module('cahierDeTexteApp')
    .controller('HeaderCtrl',
		[ '$scope', 'CurrentUser',
		  function ($scope, CurrentUser) {
		      CurrentUser.getCurrentUser().success(function( response ) {
			  $scope.current_user = response;
		      });

		  } ] );
