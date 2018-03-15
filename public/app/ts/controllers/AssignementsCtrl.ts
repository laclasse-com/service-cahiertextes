'use strict';

angular.module('cahierDeTextesClientApp')
  .controller('AssignementsCtrl',
    ['$scope', '$sce', '$timeout', 'toastr', '$state', 'moment',
      'APP_PATH', 'URL_DOCS', 'API', 'Annuaire', 'Devoirs', 'Cours', 'CreneauxEmploiDuTemps', 'CurrentUser',
      function($scope, $sce, $timeout, toastr, $state, moment,
        APP_PATH, URL_DOCS, API, Annuaire, Devoirs, Cours, CreneauxEmploiDuTemps, CurrentUser) {
        let ctrl = $scope;

        ctrl.affiche_faits = false;
        ctrl.tri_ascendant = true;
        ctrl.popup_ouverte = false;
        ctrl.matiere_selected = null;

        let getCours = _.memoize(function(id) {
          return Cours.get({ id: id });
        });

        let getCreneauxEmploiDuTemps = _.memoize(function(id) {
          return CreneauxEmploiDuTemps.get({ id: id });
        });

        ctrl.filter_data = function(matiere) {
          if (_(matiere).isNull()) {
            ctrl.devoirs = ctrl.all_devoirs;
          } else {
            ctrl.devoirs = _(ctrl.all_devoirs).select(function(devoir) {
              return devoir.creneau_emploi_du_temps.matiere_id == matiere.id;
            });
          }
        };

        ctrl.period_offset = 0;

        // retrieve_data() when the value of week_offset changes
        // n.b.: triggered when period_offset is initialized above
        let nb_mois_depuis_septembre = Math.abs(9 - (moment().month() + 1));
        ctrl.period_offsets_list = _.range(nb_mois_depuis_septembre, (10 - nb_mois_depuis_septembre) * -1, -1)
          .map(function(offset) {
            return {
              offset: offset,
              label: offset == 0 ? 'ce mois' : moment().add(offset * -1, 'months').fromNow()
            };
          });

        ctrl.incr_offset = function() { ctrl.period_offset++; };
        ctrl.decr_offset = function() { ctrl.period_offset--; };
        ctrl.reset_offset = function() { ctrl.period_offset = 0; };

        CurrentUser.get()
          .then(function(response) {
            ctrl.current_user = response.data;

            let retrieve_data = function() {
              ctrl.from_date = moment().subtract(ctrl.period_offset, 'months').subtract(2, 'weeks').toDate();
              ctrl.to_date = moment().subtract(ctrl.period_offset, 'months').add(2, 'weeks').toDate();

              API.query_devoirs({
                'date_due>': ctrl.from_date,
                'date_due<': ctrl.to_date,
                'groups_ids[]': ctrl.current_user.enfant_actif ? _(ctrl.current_user.enfant_actif.enfant.groups).pluck('group_id') : _(ctrl.current_user.groups).pluck('group_id'),
                'uid': ctrl.current_user.enfant_actif ? ctrl.current_user.enfant_actif.child_id : ctrl.current_user.id,
                'check_done': ctrl.current_user.is(['ELV'])
              })
                .$promise.then(function(response) {
                  ctrl.matieres = {};

                  ctrl.all_devoirs = _(response).map(function(devoir) {
                    devoir.cours = getCours(devoir.cours_id);
                    devoir.creneau_emploi_du_temps = getCreneauxEmploiDuTemps(devoir.creneau_emploi_du_temps_id);

                    devoir.creneau_emploi_du_temps.$promise
                      .then(function() {
                        Annuaire.get_subject(devoir.creneau_emploi_du_temps.matiere_id)
                          .then(function(response) {
                            devoir.matiere = response.data;
                            ctrl.matieres[devoir.matiere.id] = devoir.matiere;
                          });
                      });

                    _(devoir.ressources).each(function(ressource) {
                      ressource.url = $sce.trustAsResourceUrl(`${URL_DOCS}/api/connector?cmd=file&target=${ressource.hash}`);
                    });

                    return devoir;
                  });
                  ctrl.filter_data(ctrl.matiere_selected);
                });
            };


            ctrl.$watch('period_offset', function() {
              retrieve_data();
            });
          });
      }]);
