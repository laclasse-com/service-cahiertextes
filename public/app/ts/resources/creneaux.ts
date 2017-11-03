angular.module('cahierDeTextesClientApp')
  .factory('CreneauxEmploiDuTemps',
  ['$resource', 'APP_PATH',
    function($resource, APP_PATH) {
      return $resource(`${APP_PATH}/api/creneaux_emploi_du_temps/:id`,
        {
          id: '@id',
          regroupement_id: '@regroupement_id',
          previous_regroupement_id: '@previous_regroupement_id',
          jour_de_la_semaine: '@jour_de_la_semaine',
          heure_debut: '@heure_debut',
          heure_fin: '@heure_fin',
          matiere_id: '@matiere_id',
          semainier_regroupement: '@semainier_regroupement',
          semainier_salle: '@semainier_salle'
        },
        {
          update: { method: 'PUT' },
          delete: {
            method: 'DELETE',
            params: {
              id: '@id',
              date_creneau: '@date_creneau'
            }
          },
          bulk: {
            method: 'POST',
            isArray: true,
            url: `${APP_PATH}/api/creneaux_emploi_du_temps/bulk`,
            params: { creneaux_emploi_du_temps: '@creneaux_emploi_du_temps' }
          },
          bulk_delete: {
            method: 'DELETE',
            isArray: true,
            url: `${APP_PATH}/api/creneaux_emploi_du_temps/bulk`,
            params: {
              ids: '@ids',
              date_creneau: '@date_creneau'
            }
          }
        });
    }])
