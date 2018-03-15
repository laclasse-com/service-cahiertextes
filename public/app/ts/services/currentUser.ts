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
              response.data.profil_actif.admin = _(response.data.profils)
                .findWhere({
                  structure_id: response.data.profil_actif.structure_id,
                  type: 'ADM'
                }) != undefined;

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
              response.data.is_x_in_structure = _.memoize(function(types, structure_id) {
                return _.chain(response.data.profiles)
                  .select((profil) => structure_id == undefined || profil.structure_id == structure_id)
                  .pluck('type')
                  .intersection(types)
                  .value()
                  .length > 0;
              });

              response.data.is = function(types) {
                return response.data.is_x_in_structure(types, undefined);
              };

              response.data.is_x_for_group = function(types, group_id) {
                let profiles = response.data.groups.filter((group) => group.group_id == group_id)

                return profiles.length > 0 ||
                  _.chain(profiles).pluck('type').intersection(types).value().length > 0
              }
            };

          return response;
        });
      });

this.update_parameters = function(parametres) {
  return $http.put(`${APP_PATH}/api/users/current/parametres`,
    { parameters: JSON.stringify(parametres) });
};
      }])
