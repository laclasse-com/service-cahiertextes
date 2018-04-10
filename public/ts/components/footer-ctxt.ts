'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .component( 'footerCtxt',
              { controller: [ '$state', '$stateParams', 'VERSION', 'CurrentUser',
                              function( $state, $stateParams, VERSION, CurrentUser ) {
                                let ctrl = this;

                                ctrl.version = VERSION;

                                CurrentUser.get().then( function( response ) {
                                  ctrl.current_user = response;

                                  ctrl.save_and_reload = function() {
                                    CurrentUser.update_parameters( ctrl.current_user.parametrage_cahier_de_textes )
                                      .then( function() {
                                        $state.transitionTo( $state.current, $stateParams, { reload: true, inherit: true, notify: true } );
                                      } );
                                  };
                                } );
                              }],
template: `
<footer class="col-md-12" ng:cloak>
  <div class="pull-left">
    <div class="btn-group" uib-dropdown>
      <button uib-dropdown-toggle type="button" class="btn btn-xs btn-default uib-dropdown-toggle">
        <span class="glyphicon glyphicon-cog"></span> Préférences
      </button>
      <ul uib-dropdown-menu class="uib-dropdown-menu user-preferences" role="menu">
        <li ng:if="$ctrl.current_user.is(['ADM'])"><a class="btn btn-warning"
                                                      ui:sref="import">
            <span class="glyphicon glyphicon-import"></span> Import Pronote
        </a></li>
        <li ng:if="$ctrl.current_user.is(['ADM'])" class="divider"></li>
        <li><label><checkbox ng:model="$ctrl.current_user.parametrage_cahier_de_textes.affichage_week_ends"
                             ng:change="$ctrl.save_and_reload()"></checkbox> Afficher les week-ends</label></li>
        <li><label><checkbox ng:model="$ctrl.current_user.parametrage_cahier_de_textes.affichage_types_de_devoir"
                             ng:change="$ctrl.save_and_reload()"></checkbox> Afficher les types de devoirs</label></li
                                                                                                                    </ul>
    </div>
  </div>
  <a href="https://github.com/laclasse-com/service-cahiertextes" class="pull-right">version {{$ctrl.version}}</a>
</footer>
`} );
