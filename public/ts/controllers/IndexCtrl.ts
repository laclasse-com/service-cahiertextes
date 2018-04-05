'use strict';

angular.module('cahierDeTextesClientApp')
  .controller('IndexCtrl',
    ['$scope', '$state', 'CurrentUser',
      function($scope, $state, CurrentUser) {
        let ctrl = $scope;

        CurrentUser.get()
          .then(function(response) {
            let user = response;

            ctrl.tabs = _.chain(user.profiles)
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
          });
      }]);
