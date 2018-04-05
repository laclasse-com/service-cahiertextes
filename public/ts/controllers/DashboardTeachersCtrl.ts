'use strict';

angular.module('cahierDeTextesClientApp')
  .controller('DashboardTeachersCtrl',
  ['$scope', '$locale', '$q', 'API', 'Annuaire', 'current_user', 'PIECHART_DEFINITION',
    function($scope, $locale, $q, API, Annuaire, current_user, PIECHART_DEFINITION) {
      let ctrl = $scope;
      ctrl.$ctrl = ctrl;

      ctrl.scope = ctrl;

      ctrl.select_all_regroupements = function() {
        ctrl.selected_regroupements = ctrl.regroupements;
        ctrl.filter_data();
      };

      ctrl.select_no_regroupements = function() {
        ctrl.selected_regroupements = [];
        ctrl.filter_data();
      };

      ctrl.filter_data = function() {
        _(ctrl.individualCharts.enseignants)
          .each(function(chart) {
            chart.display = !_.chain(chart.enseignant.details.groups)
              .pluck('group_id')
              .intersection(_(ctrl.selected_regroupements).pluck('id'))
              .isEmpty()
              .value();
          });
      };

      ctrl.individualCharts = {
        enseignants: [],
        add: function(enseignant) {
          let chart = {
            enseignant: enseignant,
            display: true,
            pieChart: angular.copy(PIECHART_DEFINITION)
          };

          chart.pieChart.data = [{
            label: 'saisies non visées',
            value: enseignant.filled - enseignant.validated
          },
          {
            label: 'saisies visées',
            value: enseignant.validated
          }];

          ctrl.individualCharts.enseignants.push(chart);
        }
      };

      Annuaire.get_groups_of_structures([current_user.profil_actif.structure_id])
        .then(function success(response) {
          ctrl.regroupements = _(response.data).reject(function(group) {
            return group.type === 'GPL';
          });

          ctrl.selected_regroupements = ctrl.regroupements;
        });

      // Récupération et consommation des données
      API.query_enseignants(current_user.profil_actif.structure_id)
        .then(function success(response) {
          ctrl.raw_data = response.data;

          return Annuaire.get_users(_(ctrl.raw_data).pluck('enseignant_id'));
        })
        .then(function(response) {
          let enseignants_details = _(response.data).indexBy('id');

          _(ctrl.raw_data).each(function(enseignant) {
            enseignant.details = enseignants_details[enseignant.enseignant_id];

            let stats_enseignant = _(enseignant.classes).reduce(function(totaux, classe) {
              let stats_classe = _(classe.statistiques).reduce(function(totaux, mois) {
                return {
                  filled: totaux.filled + mois.filled,
                  validated: totaux.validated + mois.validated
                };
              }, { filled: 0, validated: 0 });

              return {
                filled: totaux.filled + stats_classe.filled,
                validated: totaux.validated + stats_classe.validated
              };
            }, { filled: 0, validated: 0 });

            // stats de l'enseignant
            enseignant.filled = stats_enseignant.filled;
            enseignant.validated = stats_enseignant.validated;

            ctrl.individualCharts.add(enseignant);
          });
        });
    }]);
