'use strict';

angular.module('cahierDeTextesClientApp')
  .component('displaySequencePedagogique',
  {
    bindings: { sp: '<' },
    template: '<h5>Séquence pédagogique du {{$ctrl.sp.date_cours | amDateFormat:\'dddd D MMMM\'}}</h5>' +
    '<div class="alert alert-default" ta-bind ng:model="$ctrl.sp.contenu"></div>' +
    '<ul ng:if="sp.ressources.length > 0">' +
    '  <li ng:repeat="ressource in sp.ressources">' +
    '    <a target="_blank" href="{{ressource.url}}">{{ressource.name}}</a>' +
    '  </li>' +
    '</ul>'
    ,
    controller: ['$sce', 'URL_DOCS',
      function($sce, URL_DOCS) {
        let ctrl = this;

        ctrl.$onInit = function() {
          if (ctrl.sp.contenu instanceof String) {
            ctrl.sp.contenu = $sce.trustAsHtml(ctrl.sp.contenu);
          }
          _(ctrl.sp.ressources).each(function(ressource) {
            ressource.url = $sce.trustAsResourceUrl(`${URL_DOCS}/api/connector?cmd=file&target=${ressource.hash}`);
          });
        };
      }]
  });
