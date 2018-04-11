'use strict';

angular.module('cahierDeTextesClientApp')
  .controller('DashboardTeacherCtrl',
    ['$scope', '$stateParams', '$q', '$locale', '$timeout', 'moment', 'toastr',
      'API', 'Cours', 'Annuaire', 'current_user', 'PIECHART_DEFINITION', 'MULTIBARCHART_DEFINITION',
      function($scope, $stateParams, $q, $locale, $timeout, moment, toastr,
        API, Cours, Annuaire, current_user, PIECHART_DEFINITION, MULTIBARCHART_DEFINITION) {
        let ctrl = $scope;
        ctrl.$ctrl = ctrl;

        ctrl.mois = _($locale.DATETIME_FORMATS.MONTH).toArray();
        ctrl.scope = ctrl;
        ctrl.moisCourant = null;
        ctrl.montre_valides = !current_user.is(['DIR']);
        ctrl.nb_saisies_visables = 0;
        ctrl.current_user = current_user;
        ctrl.enseignant_id = _($stateParams).has('enseignant_id') ? $stateParams.enseignant_id : ctrl.current_user.id;

        let calc_nb_saisies_visables = function(saisies) {
          return _(saisies).select(<any>{ recent: false, valide: false }).length;
        };

        ctrl.detail_regroupement = function(group_id) {
          _(ctrl.enseignant.liste_regroupements).findWhere({ id: group_id });
        };

        ctrl.filter_saisie = function(montre_valides, mois, selected_regroupements) {
          return function(saisie) {
            return (montre_valides || _(saisie.cours.date_validation).isNull())
              && (_(mois).isNull() || saisie.mois == mois)
              && (_.chain(selected_regroupements).pluck('id').contains(saisie.regroupement_id).value());
          };
        };

        // Graphiques
        ctrl.graphiques = {
          pieChart: angular.copy(PIECHART_DEFINITION),
          multiBarChart: angular.copy(MULTIBARCHART_DEFINITION),
          populate: function(data) {
            ctrl.graphiques.multiBarChart.data = [{
              key: 'saisies non visées',
              values: []
            },
            {
              key: 'saisies visées',
              values: []
            }];
            ctrl.graphiques.pieChart.data = [{
              label: 'saisies non visées',
              value: 0
            },
            {
              label: 'saisies visées',
              value: 0
            }];

            _.chain(data)
              .groupBy('regroupement_id')
              .each(function(regroupement) {
                let filled = regroupement.length;
                let validated = _(regroupement).where({ valide: true }).length;

                Annuaire.get_group(regroupement[0].regroupement_id)
                  .then(function success(response) {
                    _(regroupement).each(function(regroupement) { regroupement.group = response.data; });

                    ctrl.graphiques.multiBarChart.data[0].values.push({
                      key: regroupement[0].group.name,
                      x: regroupement[0].group.name,
                      y: filled - validated
                    });
                    ctrl.graphiques.multiBarChart.data[1].values.push({
                      key: regroupement[0].group.name,
                      x: regroupement[0].group.name,
                      y: validated
                    });
                  });

                ctrl.graphiques.pieChart.data[0].value += filled - validated;
                ctrl.graphiques.pieChart.data[1].value += validated;
              });
          }
        };

        ctrl.select_all_regroupements = function() {
          ctrl.selected_regroupements = ctrl.enseignant.liste_regroupements;
          ctrl.graphiques.populate(ctrl.raw_data);
        };

        ctrl.select_no_regroupements = function() {
          ctrl.selected_regroupements = [];
          ctrl.graphiques.populate(ctrl.raw_data);
        };

        ctrl.valide = function(saisie) {
          if (current_user.is(['DIR'])) {
            let disable_toastr = _(saisie).has('disable_toastr');
            saisie.cours.$valide().then(function(response) {
              saisie.valide = !_(response.date_validation).isNull();

              if (!ctrl.montre_valides && !_(response.date_validation).isNull()) {
                let date_validation_holder = response.date_validation;
                response.date_validation = null;

                $timeout(function() { response.date_validation = date_validation_holder; }, 3000);
              }

              ctrl.nb_saisies_visables = calc_nb_saisies_visables(ctrl.raw_data);
              ctrl.graphiques.populate(ctrl.raw_data);

              if (!disable_toastr) {
                toastr.success(`Séquence pédagogique ${(saisie.valide ? '' : 'dé-')}visée.`,
                  'Opération réussie');
              }
            });
          }
        };

        ctrl.valide_all = function() {
          swal({
            title: 'Tout viser ?',
            text: 'Cette action va viser toutes les saisies actuellement affichées à l\'écran.',
            type: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#ff6b55',
            confirmButtonText: 'Confirmer',
            cancelButtonText: 'Annuler'
          })
            .then(function confirm() {
              let counter = 0;
              _.chain(ctrl.raw_data)
                .reject(function(saisie) { return saisie.valide || saisie.recent; })
                .each(function(saisie) {
                  saisie.disable_toastr = true;
                  ctrl.valide(saisie);
                  counter++;
                });
              if (counter > 0) {
                let pluriel = counter > 1 ? 's' : '';
                let message = `${counter} séquence${pluriel} pédagogique${pluriel} visée${pluriel}.`;
                toastr.success(message, 'Opération réussie');
              }
            },
              function cancel() { });
        };

        // Récupération et consommation des données
        Annuaire.get_user(ctrl.enseignant_id)
          .then(function(response) {
            ctrl.enseignant = response.data;

            ctrl.enseignant.get_actual_groups()
              .then(function(response) {
                ctrl.enseignant.liste_regroupements = _.chain(response)
                  .select(function(group) {
                    return group.type !== 'GPL'
                      && ctrl.current_user.get_structures_ids().includes(group.structure_id);
                  })
                  .uniq(function(group) { return group.id; })
                  .compact()
                  .value();

                ctrl.enseignant.prof_principal = _.chain(ctrl.enseignant.groups)
                  .where({ type: 'PRI' })
                  .pluck('group_id')
                  .map(function(group_id) {
                    return _(ctrl.enseignant.liste_regroupements).findWhere({ id: group_id });
                  })
                  .value();

                ctrl.select_all_regroupements();
              });

            ctrl.enseignant.get_actual_subjects()
              .then(function(response) {
                ctrl.enseignant.liste_matieres = _.chain(response)
                  .uniq(function(subject) { return subject.id; })
                  .compact()
                  .value();
              });

            return API.get_enseignant(ctrl.current_user.get_structures_ids(), ctrl.enseignant_id);
          })
          .then(function success(response) {
            console.log(response)
            let _2_semaines_avant = moment().subtract(2, 'weeks');

            ctrl.raw_data = response.saisies.map(function(saisie, index) {
              // on référence l'index d'origine dans chaque élément pour propager la validation
              saisie.index = index;
              saisie.cours = new Cours(saisie.cours);
              saisie.regroupement_id = parseInt(saisie.regroupement_id);
              saisie.month = moment(saisie.cours.date_cours).month();
              saisie.recent = moment(saisie.cours.date_cours).isAfter(_2_semaines_avant);

              saisie.matiere = _(ctrl.enseignant.liste_matieres).findWhere({ id: saisie.matiere_id });
              if (saisie.matiere == undefined) {
                saisie.matiere = Annuaire.get_subject(saisie.matiere_id);
              }

              return saisie;
            });

            ctrl.graphiques.populate(ctrl.raw_data);
            ctrl.nb_saisies_visables = calc_nb_saisies_visables(ctrl.raw_data);
          });
      }]);
