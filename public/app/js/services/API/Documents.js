'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .service('Documents',
             [ '$http', '$q', 'DOCS_URL', 'Annuaire',
               function( $http, $q, DOCS_URL, Annuaire ) {
                   var Documents = this;

                   Documents.list_files = _.memoize( function( root ) {
                       var params = { cmd: 'open',
                                      target: '' };

                       if ( root == undefined ) {
                           params.tree = 1;
                       } else {
                           params.target = root;
                       }
                       return $http.get( DOCS_URL + '/api/connector', { params: params } );
                   } );

                   Documents.get_ctxt_folder_hash = _.memoize( function( classe ) {
                       var structure,
                           structure_root,
                           classes_root,
                           classe_root,
                           cdt_root;

                       return Annuaire.get_structure( classe.structure_id )
                           .then( function success( response ) {
                               structure = response.data;

                               return Documents.list_files();
                           } )
                           .then( function success( response ) {
                               structure_root = _(response.data.files).findWhere({ phash: null, name: structure.name });

                               return Documents.list_files( structure_root.hash );
                           } )
                           .then( function success( response ) {
                               classes_root = _(response.data.files).findWhere({ phash: structure_root.hash, name: 'classes' });

                               return Documents.list_files( classes_root.hash );
                           } )
                           .then( function success( response ) {
                               classe_root = _(response.data.files).findWhere({ phash: classes_root.hash, name: classe.name });

                               return Documents.list_files( classe_root.hash );
                           } )
                           .then( function success( response ) {
                               cdt_root = _(response.data.files).findWhere({ phash: classe_root.hash, name: 'Cahier de textes.ct' });

                               return cdt_root.hash;
                           } );
                   } );

                   Documents.ajout_au_cahier_de_textes = function( classe, hash ) {
                       return Documents.get_ctxt_folder_hash( classe )
                           .then( function( ctxt_folder_hash ) {
                               var params = { cmd: 'paste',
                                              'targets[]': [ hash ],
                                              dst: ctxt_folder_hash,
                                              cut: false };

                               return $http.get( DOCS_URL + '/api/connector', { params: params } );
                           } )
                           .then( function success( response ) {
                               return response.data;
                           } );
                   };

                   Documents.upload_dans_cahier_de_textes = function( classe, fichiers ) {
                       return Documents.get_ctxt_folder_hash( classe )
                           .then( function( ctxt_folder_hash ) {
                               return $q.all( _(fichiers).map( function( file ) {
                                   var form_data = new FormData();
                                   form_data.append( 'cmd', 'upload' );
                                   form_data.append( 'target', ctxt_folder_hash );
                                   form_data.append( 'upload[]', file );

                                   return $http.post( DOCS_URL + '/api/connector',
                                                      form_data,
                                                      { headers: {'Content-Type': undefined },
                                                        transformRequest: angular.identity }
                                                    );
                               } ) )
                                   .then( function( response ) {
                                       return response;
                                   } );
                           } );
                   };
               }
             ] );
