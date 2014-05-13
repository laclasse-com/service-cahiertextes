'use strict';

angular.module('cahierDeTexteApp')
    .service('Documents',
	     [ '$http',
	       function( $http ) {
		   this.list_files = function( root ) {
		       $http.get( "http://www.dev.laclasse.com/docs-beta/api/connector?cmd=open&target=" )
			   .success( function( response ) {
			       console.debug(response)
			   } );
		   };
	       }
	     ] );
