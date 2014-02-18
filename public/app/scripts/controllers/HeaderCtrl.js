'use strict';

angular.module('cahierDeTexteApp')
    .controller('HeaderCtrl',
		[ '$scope', '$location', 'User',
		  function ( $scope, $location, User ) {
		      User.get_user().success( function( response ) {
			  $scope.current_user = response;
		      });
		  } ] );
