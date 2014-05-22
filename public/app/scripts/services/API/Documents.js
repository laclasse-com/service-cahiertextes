'use strict';

angular.module('cahierDeTexteApp')
    .service('Documents',
	     [ '$http', 'DOCS_URL',
	       function( $http, DOCS_URL ) {
		   this.list_files = function( root ) {
		       root = typeof root === 'undefined' ? '&init=1' : root;
		       return $http.get( DOCS_URL + "/api/connector?cmd=open&target=" + root );
		   };
	       }
	     ] );
