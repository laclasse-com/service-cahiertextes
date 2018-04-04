'use strict';

angular.module('cahierDeTextesClientApp')
  .service('Redirection',
    ['$state', 'CurrentUser',
      function($state, CurrentUser) {
        this.doorman = function(allowed_types) {
          CurrentUser.get().then(function(response) {
            if (allowed_types.length == 0
              || (_.chain(allowed_types).intersection(_(response.data.profiles).pluck('type')).isEmpty().value()
                && !(response.data.is(['ADM']))
              )
            ) {
              // traiter le raffraichissement de l'app en fonction du changement de profil actif
              let stateName = '404';

              if (response.data.is(['DIR'])) {
                stateName = 'enseignants';
              } else {
                stateName = 'emploi_du_temps';
              }
              $state.go(stateName, $state.params, { reload: true, inherit: true, notify: true });
            }
          });
        };
      }
    ]);
