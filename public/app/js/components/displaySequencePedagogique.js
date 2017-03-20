'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .component( 'displaySequencePedagogique',
                { bindings: { sp: '<' },
                  template: '<h5>Séquence pédagogique du {{$ctrl.sp.date_cours | amDateFormat:\'dddd D MMMM\'}}</h5>' +
                  '<div class="alert alert-default" ng:bind-html="$ctrl.sp.contenu"></div>' +
                  '<ul ng:if="cours.ressources.length > 0">' +
                  '  <li ng:repeat="ressource in cours.ressources">' +
                  '    <a target="_blank" href="{{ressource.url}}">{{ressource.name}}</a>' +
                  '  </li>' +
                  '</ul>',
                  controller: [ '$sce', 'DOCS_URL',
                                function( $sce, DOCS_URL ) {
                                    var ctrl = this;

                                    ctrl.$onInit = function() {
                                        ctrl.sp.contenu = $sce.trustAsHtml( ctrl.sp.contenu );
                                        _(ctrl.sp.ressources).each( function( ressource ) {
                                            ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
                                        } );
                                    };
                                } ]
                } );
