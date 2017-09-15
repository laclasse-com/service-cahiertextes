'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .component( 'displayDevoir',
                { bindings: { devoir: '=' },
                  template: '<div ng:class="{ \'type1\': $ctrl.devoir.type_devoir_id === 1,' +
                  ' \'type2\': $ctrl.devoir.type_devoir_id === 2,' +
                  ' \'type3\': $ctrl.devoir.type_devoir_id === 3,' +
                  ' \'type4\': $ctrl.devoir.type_devoir_id === 4,' +
                  ' \'type5\': $ctrl.devoir.type_devoir_id === 5,' +
                  ' \'type6\': $ctrl.devoir.type_devoir_id === 6,' +
                  ' \'fait\': $ctrl.devoir.fait,' +
                  ' \'a-faire\': !$ctrl.devoir.fait }">' +
                  '    <h5><i class="picto" ng:style="{\'background-image\':\'url(\' + $ctrl.app_path + \'/app/node_modules/laclasse-common-client/images/picto_matiere.svg)\'}"></i> {{$ctrl.devoir.matiere.name}} </h5>' +
                  '    <h6><i class="picto" ng:style="{\'background-image\':\'url(\' + $ctrl.app_path + \'/app/node_modules/laclasse-common-client/images/picto_devoir.svg)\'}"></i> {{$ctrl.devoir.type_devoir.description}} : </h6>' +
                  '    <span ng:if="$ctrl.display_time_estimation && $ctrl.devoir.temps_estime > 0"><i class="picto" ng:style="{\'background-image\':\'url(\' + $ctrl.app_path + \'/app/node_modules/laclasse-common-client/images/picto_temps.svg)\'}"></i> Temps estimé : <em>{{$ctrl.devoir.temps_estime * 5}} minutes</em></span>' +
                  '    <div class="alert alert-default" ng:bind-html="$ctrl.devoir.contenu"></div>' +
                  '    <div class="row col-md-12 ressources">' +
                  '      <div class="attached-document" ng:repeat="ressource in $ctrl.devoir.ressources">' +
                  '        <a target="_blank" href="{{ressource.url}}">{{ressource.name}}</a>' +
                  '      </div>' +
                  '    </div>' +
                  '</div>',
                  controller: [ '$sce', 'URL_DOCS', 'APP_PATH', 'API',
                                function( $sce, URL_DOCS, APP_PATH, API ) {
                                    var ctrl = this;

                                    ctrl.$onInit = function() {
                                        ctrl.app_path = APP_PATH;
                                        ctrl.display_time_estimation = false;

                                        ctrl.devoir.contenu = $sce.trustAsHtml( ctrl.devoir.contenu );
                                        API.get_type_de_devoir( ctrl.devoir.type_devoir_id ).$promise
                                            .then( function( response ) {
                                                ctrl.devoir.type_devoir = response;
                                            } );

                                        _(ctrl.devoir.ressources).each( function( ressource ) {
                                            ressource.url = $sce.trustAsResourceUrl( URL_DOCS + '/api/connector?cmd=file&target=' + ressource.hash );
                                        } );
                                    };
                                } ]
                } );
