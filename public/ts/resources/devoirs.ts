angular.module('cahierDeTextesClientApp')
  .factory('Devoirs',
  ['$resource', 'APP_PATH',
    function($resource, APP_PATH) {
      return $resource(`${APP_PATH}/api/devoirs/:id`,
        {
          id: '@id',
          uid: '@uid'
        },
        {
          update: { method: 'PUT' },
          fait: {
            method: 'PUT',
            url: `${APP_PATH}/api/devoirs/:id/fait`
          },
          copie: {
            method: 'PUT',
            url: `${APP_PATH}/api/devoirs/:id/copie/cours/:cours_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date_due/:date_due`,
            params: {
              id: '@id',
              cours_id: '@cours_id',
              creneau_emploi_du_temps_id: '@creneau_emploi_du_temps_id',
              date_due: '@date_due'
            }
          }
        });
    }])
