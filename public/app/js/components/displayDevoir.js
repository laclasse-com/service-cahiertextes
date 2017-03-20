'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .component( 'displayDevoir',
                { bindings: { devoir: '<' },
                  template: '<div ng:class="{ \'type1\': $ctrl.devoir.type_$ctrl.devoir_id === 1,' +
                  ' \'type2\': $ctrl.devoir.type_$ctrl.devoir_id === 2,' +
                  ' \'type3\': $ctrl.devoir.type_$ctrl.devoir_id === 3,' +
                  ' \'type4\': $ctrl.devoir.type_$ctrl.devoir_id === 4,' +
                  ' \'type5\': $ctrl.devoir.type_$ctrl.devoir_id === 5,' +
                  ' \'type6\': $ctrl.devoir.type_$ctrl.devoir_id === 6,' +
                  ' \'fait\': $ctrl.devoir.fait,' +
                  ' \'a-faire\': !$ctrl.devoir.fait }">' +
                  '    <h5> {{$ctrl.devoir.matiere.libelle_long}} </h5>' +
                  '    <h6> {{$ctrl.devoir.type_devoir.description}} : </h6>' +
                  '    <div class="alert alert-default" ng:bind-html="$ctrl.devoir.contenu"></div>' +
                  '    <div class="row col-md-12 ressources">' +
                  '      <div class="attached-document" ng:repeat="ressource in $ctrl.devoir.ressources">' +
                  '        <a target="_blank" href="{{ressource.url}}">{{ressource.name}}</a>' +
                  '      </div>' +
                  '    </div>' +
                  '</div>',
                  controller: function(  ) {
                      var ctrl = this;
                  }
                } );
