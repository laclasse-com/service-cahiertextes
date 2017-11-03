angular.module('cahierDeTextesClientApp')
  .service('API',
  ['$http', 'APP_PATH', 'CreneauxEmploiDuTemps', 'Cours', 'Devoirs', 'Etablissements',
    function($http, APP_PATH, CreneauxEmploiDuTemps, Cours, Devoirs, Etablissements) {
      this.get_etablissement = function(params) {
        return Etablissements.get(params);
      };

      this.query_statistiques_regroupements = function(uai) {
        return $http.get(`${APP_PATH}/api/etablissements/${uai}/statistiques/regroupements`)
      };

      this.query_types_de_devoir = _.memoize(function() {
        return $http.get(`${APP_PATH}/api/types_de_devoir`);
      });
      this.get_type_de_devoir = _.memoize(function(id) {
        return $http.get(`${APP_PATH}/api/types_de_devoir/${id}`);
      });

      this.get_emploi_du_temps = function(from, to, uai, uid) {
        return $http.get(`${APP_PATH}/api/emplois_du_temps`, {
          params: {
            debut: from,
            fin: to,
            uai: uai,
            uid: uid
          }
        });
      }

      this.get_creneau_emploi_du_temps = function(params) {
        return CreneauxEmploiDuTemps.get(params);
      };
      this.get_creneaux_emploi_du_temps_similaires = function(params) {
        return $http.get(`${APP_PATH}/api/creneaux_emploi_du_temps/${params.id}/similaires`, {
          params: {
            debut: params.debut,
            fin: params.fin
          }
        });
      };

      this.query_enseignants = function(uai) {
        return $http.get(`${APP_PATH}/api/etablissements/${uai}/statistiques/enseignants`)
      };
      this.get_enseignant = function(uai, enseignant_id) {
        return $http.get(`${APP_PATH}/api/etablissements/${uai}/statistiques/enseignants/${enseignant_id}`)
      };

      this.get_cours = function(params) {
        return Cours.get(params);
      };

      this.query_devoirs = function(params) {
        return Devoirs.query(params);
      };
      this.get_devoir = function(params) {
        return Devoirs.get(params);
      };
    }
  ]);
