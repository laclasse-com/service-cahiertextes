'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .component( 'displayDevoir',
                { bindings: { devoir: '=' },
                  template: '<div ng:class="{ \'type1\': $ctrl.devoir.type_$ctrl.devoir_id === 1,' +
                  ' \'type2\': $ctrl.devoir.type_$ctrl.devoir_id === 2,' +
                  ' \'type3\': $ctrl.devoir.type_$ctrl.devoir_id === 3,' +
                  ' \'type4\': $ctrl.devoir.type_$ctrl.devoir_id === 4,' +
                  ' \'type5\': $ctrl.devoir.type_$ctrl.devoir_id === 5,' +
                  ' \'type6\': $ctrl.devoir.type_$ctrl.devoir_id === 6,' +
                  ' \'fait\': $ctrl.devoir.fait,' +
                  ' \'a-faire\': !$ctrl.devoir.fait }">' +
                  '    <h5><i class="picto" ng:style="{\'background-image\':\'url(\' + app_path + \'/app/node_modules/laclasse-common-client/images/picto_matiere.svg)\'}"></i> {{$ctrl.devoir.matiere.libelle_long}} </h5>' +
                  '    <h6><i class="picto" ng:style="{\'background-image\':\'url(\' + app_path + \'/app/node_modules/laclasse-common-client/images/picto_devoir.svg)\'}"></i> {{$ctrl.devoir.type_devoir.description}} : </h6>' +
                  // '<!-- <li ng:if="$ctrl.devoir.temps_estime > 0"><span><i class="picto" ng:style="{\'background-image\':\'url(\' + app_path + \'/app/node_modules/laclasse-common-client/images/picto_temps.svg)\'}"></i> Temps estimé : <em>{{$Ctrl.devoir.temps_estime * 5}} minutes</em></span></li> -->' +
                  // '    <div class="alert alert-default" ng:bind-html="$ctrl.devoir.contenu"></div>' +
                  // '    <div class="row col-md-12 ressources">' +
                  // '      <div class="attached-document" ng:repeat="ressource in $ctrl.devoir.ressources">' +
                  // '        <a target="_blank" href="{{ressource.url}}">{{ressource.name}}</a>' +
                  // '      </div>' +
                  // '    </div>' +
                  '</div>',
                  controller: [ '$sce', 'DOCS_URL',
                                function( $sce, DOCS_URL ) {
                                    var ctrl = this;

                                    ctrl.$onInit = function() {
                                        ctrl.devoir.contenu = $sce.trustAsHtml( ctrl.devoir.contenu );
                                        _(ctrl.devoir.ressources).each( function( ressource ) {
                                            ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
                                        } );
                                    };
                                } ]
                } );
