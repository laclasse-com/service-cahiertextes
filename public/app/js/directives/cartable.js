'use strict';

angular.module( 'cahierDeTextesClientApp' )
// https://stackoverflow.com/a/18609594/144263
    .factory( 'RecursionHelper',
              [ '$compile',
                function( $compile ) {
                    return {
                        /**
                         * Manually compiles the element, fixing the recursion loop.
                         * @param element
                         * @param [link] A post-link function, or an object with function(s) registered via pre and post properties.
                         * @returns An object containing the linking functions.
                         */
                        compile: function( element, link ) {
                            // Normalize the link parameter
                            if( angular.isFunction( link ) ) {
                                link = { post: link };
                            }

                            // Break the recursion loop by removing the contents
                            var contents = element.contents().remove();
                            var compiledContents;
                            return { pre: (link && link.pre) ? link.pre : null,
                                     /**
                                      * Compiles and re-adds the contents
                                      */
                                     post: function( scope, element ) {
                                         // Compile the contents
                                         if ( !compiledContents ) {
                                             compiledContents = $compile( contents );
                                         }
                                         // Re-add the compiled contents to the element
                                         compiledContents( scope, function( clone ) {
                                             element.append( clone );
                                         } );

                                         // Call the post-linking function, if any
                                         if ( link && link.post ) {
                                             link.post.apply( null, arguments );
                                         }
                                     }
                                   };
                        }
                    };
                } ] )
    .directive( 'cartable',
                [ 'RecursionHelper',
                  function( RecursionHelper ) {
                      return {
                          scope: { racine: '=racine',
                                   target: '=target',
                                   regroupement: '=regroupement',
                                   addCallback: '=addCallback' },
                          replace: true,
                          controller: [ '$scope', '$sce', 'URL_DOCS', 'Documents',
                                        function( $scope, $sce, URL_DOCS, Documents ) {
                                            var ctrl = $scope;
                                            ctrl.$ctrl = ctrl;

                                            ctrl.getChildren = function( noeud ) {
                                                Documents.list_files( noeud.hash ).then( function ( response ) {
                                                    noeud.children = _( response.data.files ).rest();
                                                } );
                                            };

                                            ctrl.add_ressource_to_target = function( target, node, regroupement ) {
                                                if ( target.ressources === undefined ) {
                                                    target.ressources = [];
                                                }
                                                if ( _( target.ressources ).findWhere( { hash: node.hash } ) === undefined ) {
                                                    Documents.ajout_au_cahier_de_textes( regroupement, node )
                                                        .then( ctrl.addCallback( target ),
                                                               function ( response ) {
                                                                   console.debug( response.error );
                                                        } );
                                                }
                                            };

                                            ctrl.add_ressource_already_in_CT_to_target = function( target, node ) {
                                                target.ressources.push( {
                                                    name: node.name,
                                                    hash: node.hash,
                                                    url: $sce.trustAsResourceUrl( URL_DOCS + '/api/connector?cmd=file&target=' + node.hash )
                                                } );
                                            };
                                        }
                                      ],
                          template: `
<ul class="cartable">
  <li ng:repeat="node in $ctrl.racine"
      ng:class="{'disabled': node.name == 'Cahier de textes.ct'}"
      style="list-style-type: none">
    <span class="glyphicon"
          ng:class="{'glyphicon-folder-open': node.children, 'glyphicon-folder-close': !node.children}"
          ng:if="node.mime == 'directory'"
          ng:click="$ctrl.getChildren( node )">
        {{node.name}}
    </span>
    <button class="btn btn-sm btn-success from-docs"
            style="padding:top: 0; padding:bottom: 0"
            ng:if="node.mime != 'directory'"
            ng:click="$ctrl.add_ressource_to_target( $ctrl.target, node, $ctrl.regroupement )">
      <span class="glyphicon glyphicon-plus"></span>
    </button>
    <button class="btn btn-sm btn-success from-ct"
            style="padding:top: 0; padding:bottom: 0"
            ng:if="node.mime != 'directory'"
            ng:click="$ctrl.add_ressource_already_in_CT_to_target( $ctrl.target, node )">
      <span class="glyphicon glyphicon-plus"></span>
    </button>
    <span class="glyphicon glyphicon-file" ng:if="node.mime != 'directory'">
        {{node.name}} <span ng:if="node.mime != 'directory'">({{node.mime}})</span>
    </span>
    <div cartable
         ng:if="node.mime == 'directory'"
         racine="node.children"
         target="$ctrl.target"
         regroupement="$ctrl.regroupement"
         add-callback="$ctrl.addCallback">
    </div>
  </li>
</ul>
`,
                          compile: RecursionHelper.compile
                      };
                  } ] );
