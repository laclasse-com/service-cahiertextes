'use strict';

angular.module('cahierDeTexteApp')
    .controller('HeaderCtrl',
		[ '$scope', 'User', 'Redirection',
		  function ( $scope, User, Redirection ) {
		      User.get_user().success( function( response ) {
			  $scope.current_user = response;
		      });

		      $scope.reload = function() {
			  Redirection.doorman( [  ] );
		      };
		  } ] );
