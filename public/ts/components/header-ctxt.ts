'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .component( 'headerCtxt',
              { controller: [ '$state', 'CurrentUser', 'Redirection', '$sce',
                              function( $state, CurrentUser, Redirection, $sce ) {
                                let ctrl = this;

                                ctrl.embedded = window != window.top;

                                ctrl.reload = function() {
                                  // Changement du profil actif dans l'annuaire
                                  // Rechargement de l'application
                                  Redirection.doorman( [] );
                                };

                                CurrentUser.get().then( function( response ) {
                                  ctrl.current_user = response;

                                  ctrl.tabs = _.chain(ctrl.current_user.profiles)
                                    .pluck('type')
                                    .uniq()
                                    .map((type) => {
                                      switch (type) {
                                        case 'DIR':
                                          return [{
                                            heading: 'Validation des saisies par enseignant',
                                            uisref: 'enseignants',
                                            css_class: 'glyphicon glyphicon-user',
                                            active: true
                                          },
                                                  {
                                            heading: 'Emplois du Temps',
                                            uisref: 'emploi_du_temps',
                                            css_class: 'glyphicon glyphicon-calendar',
                                            active: false
                                          }];
                                        case 'ENS':
                                          return [{
                                            heading: 'Cahier de textes',
                                            uisref: 'emploi_du_temps',
                                            css_class: 'glyphicon glyphicon-calendar',
                                            active: true
                                          },
                                                  {
                                            heading: 'Statistiques',
                                            uisref: 'stats',
                                            css_class: 'glyphicon glyphicon-stats',
                                            active: false
                                          }];
                                        case 'TUT':
                                        case 'ELV':
                                          return [{
                                            heading: 'Emploi du temps',
                                            uisref: 'emploi_du_temps',
                                            css_class: 'glyphicon glyphicon-calendar',
                                            active: true
                                          },
                                                  {
                                            heading: 'Liste des devoirs',
                                            uisref: 'devoirs',
                                            css_class: 'glyphicon glyphicon-list',
                                            active: false
                                          }];
                                        case 'ADM':
                                          return [{
                                            heading: 'Emplois du Temps',
                                            uisref: 'emploi_du_temps',
                                            css_class: 'glyphicon glyphicon-calendar',
                                            active: true
                                          }];
                                        case 'EVS':
                                          return [{
                                            heading: 'Emplois du Temps',
                                            uisref: 'emploi_du_temps',
                                            css_class: 'glyphicon glyphicon-calendar',
                                            active: true
                                          }];
                                      }
                                    })
                                    .flatten()
                                    .compact()
                                    .uniq((tab) => tab.uisref)
                                    .value();

                                  _(ctrl.tabs).each(function(tab) {
                                    tab.active = tab.uisref == $state.current.name;
                                  });

                                  ctrl.set_active_tab = function(uisref) {
                                    _(ctrl.tabs).each(function(tab) {
                                      tab.active = tab.uisref == uisref;
                                    });
                                  };

                                  ctrl.set_active_tab(ctrl.tabs[0].uisref);
                                  $state.go(ctrl.tabs[0].uisref);
                                } );
                              }],
template: `<header ng:class="{'embedded': $ctrl.embedded}">

  <div class="onglets">
    <a class="btn"
       ng:repeat="tab in $ctrl.tabs"
       ui:sref="{{tab.uisref}}"
       ng:class="{'btn-warning': tab.active, 'btn-default': !tab.active}"
       ng:click="$ctrl.set_active_tab( tab.uisref )">
      <span class="{{tab.css_class}}"></span> {{tab.heading}}
    </a>

    <div class="pull-right" ng:if="$ctrl.current_user.children.length > 0">
      <select class="choix-enfant"
              ng:options="child as child.user.firstname+' '+child.user.lastname for child in $ctrl.current_user.children track by child.user.id"
              ng:model="$ctrl.current_user.enfant_actif"
              ng:change="$ctrl.reload()">
      </select>
      <button class="btn btn-warning" ng:click="$ctrl.current_user.enfant_actif = null; $ctrl.reload()">⌫</button>
    </div>
  </div>
</header>
`} );
