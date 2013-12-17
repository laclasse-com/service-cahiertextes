'use strict';

angular.module('cahierDeTexteApp')
    .service('CurrentUser',
	     [ '$http', 'Users',
	       function( $http, Users ) {
		   this.getCurrentUser = function() {
		       var current_user = $http.get( '/api/v0/current_user' ).success(function( response ) {
			   Users.get({ user_id: response.uid }).$promise.then(function( details ) {
			       response.details = details;
			   });
			   return response;
		       });
		       return current_user;
		   };
	       } ] );
