'use strict';

angular.module('cahierDeTexteApp')
    .service('Documents',
	     [ '$http', 'DOCS_URL',
	       function( $http, DOCS_URL ) {
		   this.list_files = function( root ) {
		       root = typeof root === 'undefined' ? '&init=1' : root;
		       return $http.get( DOCS_URL + "/api/connector?cmd=open&target=" + root );
		   };

		   this.ajout_au_cahier_de_textes = function( share_id, hash ) {
		       return $http.get( DOCS_URL + "/api/ctxt/copy?cmd=paste&targets[]=" + hash + "&cut=0&attachment=CAHIERTXT&share=" + share_id );
		   };
	       }
	     ] );
