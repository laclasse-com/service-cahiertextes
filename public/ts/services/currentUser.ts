angular.module('cahierDeTextesClientApp')
  .service('CurrentUser',
    ['$http', '$q', 'APP_PATH', 'Annuaire',
     function($http, $q, APP_PATH, Annuaire) {
        this.get = _.memoize(function() {
          return $http.get(`${APP_PATH}/api/users/current`)
            .then(function(response) {
              let current_user = response.data;
              _(current_user.profiles).each(function(profil) {
                // Liste des regroupements liées au profil
                profil.regroupements = _.chain(current_user.regroupements)
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

              if (current_user.children.length > 0) {
                current_user.children.map(function(child) {
                  return Annuaire.get_user(child.child_id)
                    .then(function(user) {
                      child.user = user.data;
                    });
                });
              }

              current_user.get_actual_groups = function() {
                let promise = $q.resolve([]);
                let groups_ids = _.chain(current_user.groups).pluck('group_id').uniq().value();
                promise = Annuaire.get_groups(groups_ids);

                return promise
                  .then(function(groups) {
                    current_user.actual_groups = groups.data;

                    return $q.resolve(current_user.actual_groups);
                  });
              };

              current_user.extract_subjects_ids = function() {
                return _.chain(current_user.groups).pluck('subject_id').uniq().value();
              };

              current_user.get_actual_subjects = function() {
                return Annuaire.get_subjects(current_user.extract_subjects_ids())
                  .then(function(subjects) {
                    current_user.actual_subjects = subjects.data;

                    return $q.resolve(current_user.actual_subjects);
                  });
              };

              current_user.get_structures_ids = _.memoize((desired_types) => {
                return _.chain(current_user.profiles)
                  .select((profil) => desired_types == undefined || desired_types.includes(profil.type))
                  .pluck("structure_id")
                  .uniq()
                  .value();
              });

              // Voir quel est le profil
              current_user.is_x_in_structure = _.memoize(function(types, structure_id) {
                return _.chain(current_user.profiles)
                  .select((profil) => structure_id == undefined || profil.structure_id == structure_id)
                  .pluck('type')
                  .intersection(types)
                  .value()
                  .length > 0;
              });

              current_user.is = function(types) {
                return current_user.is_x_in_structure(types, undefined);
              };

              current_user.is_x_for_group = function(types, group_id) {
                let profiles = current_user.groups.filter((group) => group.group_id == group_id)

                return profiles.length > 0 ||
                  _.chain(profiles).pluck('type').intersection(types).value().length > 0;
              };

              return current_user;
            });
        });

        this.update_parameters = function(parametres) {
          return $http.put(`${APP_PATH}/api/users/current/parametres`,
            { parameters: JSON.stringify(parametres) });
        };
      }])
