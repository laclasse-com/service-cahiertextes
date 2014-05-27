'use strict';

angular.module('cahierDeTexteApp')
    .service('Documents',
	     [ '$http', '$upload', 'DOCS_URL',
	       function( $http, $upload, DOCS_URL ) {
		   this.list_files = function( root ) {
		       root = typeof root === 'undefined' ? '&init=1' : root;
		       return $http.get( DOCS_URL + "/api/connector?cmd=open&target=" + root );
		   };

		   this.ajout_au_cahier_de_textes = function( share_id, hash ) {
		       return $http.get( DOCS_URL + "/api/ctxt/copy?cmd=paste&targets[]=" + hash + "&cut=0&attachment=CAHIERTXT&share=" + share_id );
		   };

		   this.upload_dans_cahier_de_textes = function( share_id, fichiers ) {
		       return $upload.http({ url: DOCS_URL + "/api/ctxt/add",
					     data: { current: 0,
						     attachment: 'CAHIERTXT',
						     share: share_id },
					     file: fichiers });
		   };
	       }
	     ] );
