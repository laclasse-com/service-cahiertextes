angular.module('cahierDeTextesClientApp')
  .service('API',
           ['$http', '$q', 'APP_PATH', 'CreneauxEmploiDuTemps', 'Cours', 'Devoirs',
            function($http, $q, APP_PATH, CreneauxEmploiDuTemps, Cours, Devoirs) {
              let API = this;

              API.query_statistiques_regroupements = function(uai) {
                return $http.get(`${APP_PATH}/api/etablissements/${uai}/statistiques/regroupements`)
              };

              API.query_types_de_devoir = _.memoize(function() {
                return $http.get(`${APP_PATH}/api/types_de_devoir`);
              });
              API.get_type_de_devoir = _.memoize(function(id) {
                return $http.get(`${APP_PATH}/api/types_de_devoir/${id}`);
              });

              API.get_emploi_du_temps = function(from, to, uid, groups_ids, subjects_ids) {
                return $http.get(`${APP_PATH}/api/emplois_du_temps`, {
                  params: {
                    debut: from,
                    fin: to,
                    uid: uid,
                    "groups_ids[]": groups_ids,
                    "subjects_ids[]": subjects_ids
                  }
                });
              }

              API.get_creneau_emploi_du_temps = function(params) {
                return CreneauxEmploiDuTemps.get(params);
              };
              API.get_creneaux_emploi_du_temps_similaires = function(params) {
                return $http.get(`${APP_PATH}/api/creneaux_emploi_du_temps/${params.id}/similaires`, {
                  params: {
                    debut: params.debut,
                    fin: params.fin
                  }
                });
              };

              API.query_enseignants = function(uais) {
                return $q.all(uais.map((uai) => $http.get(`${APP_PATH}/api/etablissements/${uai}/statistiques/enseignants`)))
                  .then((responses) => _.chain(responses).pluck("data").flatten().value());
              };

              API.get_enseignant = function(uais, enseignant_id) {
                return $q.all(uais.map((uai) => $http.get(`${APP_PATH}/api/etablissements/${uai}/statistiques/enseignants/${enseignant_id}`)))
                  .then((responses) => {
                    let response = _.chain(responses)
                      .pluck("data")
                      .flatten()
                      .value();

                    return { enseignant_id: response[0].enseignant_id,
                             saisies: _.chain(response).pluck("saisies").flatten().value() };
                  });
              };

              API.get_cours = function(params) {
                return Cours.get(params);
              };

              API.query_devoirs = function(params) {
                return Devoirs.query(params);
              };
              API.get_devoir = function(params) {
                return Devoirs.get(params);
              };
            }
    ]);
