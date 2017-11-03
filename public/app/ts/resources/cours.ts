angular.module('cahierDeTextesClientApp')
  .factory('Cours',
  ['$resource', 'APP_PATH',
    function($resource, APP_PATH) {
      return $resource(`${APP_PATH}/api/cours/:id`,
        { id: '@id' },
        {
          update: { method: 'PUT' },
          valide: {
            method: 'PUT',
            url: `${APP_PATH}/api/cours/:id/valide`
          },
          copie: {
            method: 'PUT',
            url: `${APP_PATH}/api/cours/:id/copie/regroupement/:regroupement_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date/:date`,
            params: {
              id: '@id',
              regroupement_id: '@regroupement_id',
              creneau_emploi_du_temps_id: '@creneau_emploi_du_temps_id',
              date: '@date'
            }
          }
        });
    }])
