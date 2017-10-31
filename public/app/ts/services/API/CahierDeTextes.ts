'use strict';

angular.module('cahierDeTextesClientApp')
  .service('CurrentUser',
  ['$http', '$q', 'APP_PATH', 'Annuaire',
    function($http, $q, APP_PATH, Annuaire) {
      this.get = _.memoize(function() {
        return $http.get(`${APP_PATH}/api/users/current`)
          .then(function(response) {
            _(response.data.profils).each(function(profil) {
              // Liste des regroupements liées au profil
              profil.regroupements = _.chain(response.data.regroupements)
                .filter(function(classe) { return classe.etablissement_code == profil.structure_id; })
                .map(function(classe) {
                  return {
                    id: classe.id,
                    libelle: classe.name,
                    type: classe.type
                  };
                })
                .uniq(function(item) { return item.id; })
                .reject(function(item) { return _.isUndefined(item.id); })
                .value();
            });
            response.data.profil_actif = _(response.data.profils).findWhere({ active: true });
            response.data.profil_actif.admin = !_.chain(response.data.profils)
              .findWhere({
                structure_id: response.data.profil_actif.structure_id,
                type: 'ADM'
              })
              .isUndefined()
              .value();

            if (response.data.enfants.length > 0) {
              let promises = response.data.enfants.map(function(child) {
                return Annuaire.get_user(child.child_id)
                  .then(function(user) {
                    child.enfant = user.data;
                  });
              });
              $q.all(promises).then(function() {
                response.data.enfant_actif = response.data.enfants[0];
              });
            }

            response.data.get_actual_groups = function() {
              let groups_ids = _.chain(response.data.groups).pluck('group_id').uniq().value();
              let promise = $q.resolve([]);
              if (_(['EVS', 'DIR', 'ADM']).contains(response.data.profil_actif.type) || response.data.profil_actif.admin) {
                promise = Annuaire.get_groups_of_structures([response.data.profil_actif.structure_id]);
              } else {
                promise = Annuaire.get_groups(groups_ids);
              }

              return promise
                .then(function(groups) {
                  response.data.actual_groups = _(groups.data).select(function(group) {
                    return (group.structure_id == response.data.profil_actif.structure_id) || (group.type == 'GPL');
                  });

                  return $q.resolve(response.data.actual_groups);
                });
            };

            response.data.extract_subjects_ids = function() {
              return _.chain(response.data.groups).pluck('subject_id').uniq().value();
            };

            response.data.get_actual_subjects = function() {
              return Annuaire.get_subjects(response.data.extract_subjects_ids())
                .then(function(subjects) {
                  response.data.actual_subjects = subjects.data;

                  return $q.resolve(response.data.actual_subjects);
                });
            };

            // Voir quel est le profil
            response.data.is = function(type) {
              return this.profil_actif.type == type;
            };

            return response;
          });
      });

      this.update_parameters = function(parametres) {
        return $http.put(`${APP_PATH}/api/users/current/parametres`,
          { parameters: JSON.stringify(parametres) });
      };
    }])

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

  .factory('Etablissements',
  ['$resource', 'APP_PATH',
    function($resource, APP_PATH) {
      return $resource(`${APP_PATH}/api/etablissements/:uai`,
        { uai: '@uai' });
    }])

  .factory('Salles',
  ['$resource', 'APP_PATH',
    function($resource, APP_PATH) {
      return $resource(`${APP_PATH}/api/salles/:id`,
        { id: '@id' },
        {
          bulk: {
            method: 'POST',
            isArray: true,
            url: `${APP_PATH}/api/salles/bulk`,
            params: { salles: '@salles' }
          }
        });
    }])

  .factory('Matchable',
  ['$resource', 'APP_PATH',
    function($resource, APP_PATH) {
      return $resource(`${APP_PATH}/api/matchables/:uai/:hash_item`,
        {
          uai: '@uai',
          hash_item: '@hash_item',
          id_annuaire: '@id_annuaire'
        });
    }]);

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
