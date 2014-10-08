'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .config( [ '$httpProvider',
	       function( $httpProvider ) {
		   $httpProvider.interceptors.push( [ '$q',
						      function( $q ) {
							  return {
							      'response': function( response ) {
								  //Will only be called for HTTP up to 300
								  return response;
							      },
							      'responseError': function( rejection ) {
								  if ( rejection.status === 401 ) {
								      location.reload();
								  }
								  return $q.reject( rejection );
							      }
							  };
						      } ] );
	       } ] );
