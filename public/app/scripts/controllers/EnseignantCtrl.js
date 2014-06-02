'use strict';

angular.module('cahierDeTexteApp')
    .controller('EnseignantCtrl',
		[ '$scope', 'User', 
		  function ( $scope, User ) {
		      User.get_user().success( function( response ) {
			  $scope.current_user = response;
		      });

		  } ] );
