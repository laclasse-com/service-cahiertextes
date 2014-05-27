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

		   this.upload_dans_cahier_de_textes = function( share_id, fichiers ) {
		       var form_data = new FormData();
		       form_data.append( 'id', 'upload' );
		       form_data.append( 'cmd', 'upload' );
		       form_data.append( 'current', 0 );
		       form_data.append( 'attachment', 'CAHIERTXT' );
		       form_data.append( 'share', share_id );
		       form_data.append( 'upload[]', fichiers );
		       return $http.post( DOCS_URL + '/api/ctxt/add',
					  form_data,
					  { headers: {'Content-Type': undefined },
					    transformRequest: function( data ) { return data; }
					  } );
		   };
	       }
	     ] );
