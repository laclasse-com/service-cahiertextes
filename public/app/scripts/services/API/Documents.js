'use strict';

angular.module('cahierDeTexteApp')
    .service('Documents',
	     [ '$http',
	       function( $http ) {
		   this.list_files = function( root ) {
		       root = typeof root === 'undefined' ? '&init=1' : root;
		       return $http.get( "http://www.dev.laclasse.com/docs-beta/api/connector?cmd=open&target=" + root );
		   };
	       }
	     ] );
