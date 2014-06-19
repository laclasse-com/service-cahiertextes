'use strict';

angular.module('cahierDeTexteApp')
        .controller('StatsEnseignantCtrl',
                ['$scope', '$stateParams', '$q',
                    '$locale', 'THEME',
                 'API', 'Cours', 'Annuaire', 'User', '$sce', 'PIECHART_DEFINITION', 'BARCHART_DEFINITION', 
                 function( $scope, $stateParams, $q, $locale, THEME, API, Cours, Annuaire, User, $sce, PIECHART_DEFINITION, BARCHART_DEFINITION ) {
                            $scope.classe = null;
                            $scope.mois = $locale.DATETIME_FORMATS.MONTH;
                            $scope.moisCourant = null;
                            $scope.gridSaisies = [];
                            $scope.selectedSaisies = [];
                            $scope.matieres = {};
                            $scope.classes = {};
                            $scope.montre_valides = false;
                                                        
                        $scope.filtre = function(saisies) {
                            var data = saisies;
                            if ($scope.moisCourant != null) {
                                data = _(data).where({mois: $scope.moisCourant + 1});
                            }
                            if ($scope.classe != null) {
                                // .invert() suppose que les valeurs sont uniques
                                var id = _($scope.classes).invert()[$scope.classe];
                                data = _(data).where({regroupement_id: id});
                            }
                            return data;
                        };

                        // Tableau
                        $scope.grid = {
                            data: 'gridSaisies',
                            selectedItems: $scope.selectedSaisies,
                            enableCellEdit: false,
                            plugins: [new ngGridFlexibleHeightPlugin()],
                            rowHeight: 64,
                            columnDefs: [
                                {field: 'classe', displayName: 'Classe',
                                    cellTemplate: '<span data-ng-bind="classes[row.entity.regroupement_id]"></span>'},
                                {field: 'matiere', displayName: 'Matière',
                                    cellTemplate: '<span data-ng-bind="matieres[row.entity.matiere_id]"></span>'},
                                {field: 'cours', displayName: 'Cours',
                                    cellTemplate: '<span class="scrollbar" data-ng-bind-html="row.entity.cours.contenu"></span>'},
                                {field: 'devoir', displayName: 'Travail à faire',
                                    cellTemplate: '<span class="scrollbar" data-ng-bind-html="row.entity.devoir.contenu"></span>'},
                                {field: 'validated', displayName: 'Visée',
                                    cellTemplate: '<div class="ngSelectionCell">' +
                                            '<i class="glyphicon glyphicon-ok-sign" data-ng-model="row.entity.valide" data-ng-show="row.entity.valide"></i>' +
                                            '<input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" data-ng-model="row.entity.valide" data-ng-hide="row.entity.valide || current_user.is( \'ENS\' )" data-ng-click="grid.valide( row )" />' +
                                            '</div>'
                                }
                            ],
                            valide: function(row) {
                                row.entity.cours.$valide();
                                row.entity.valide = true;
                                $scope.raw_data[ row.entity.index ].valide = true;
                                $scope.graphiques.populate($scope.gridSaisies);
                            },
                            valideSelection: function() {
                                _($scope.selectedSaisies).each(function(saisie) {
                                    saisie.cours.$valide();
                                    saisie.valide = true;
                                    $scope.raw_data[ saisie.index ].valide = true;
                                });
                                $scope.graphiques.populate($scope.gridSaisies);
                            },
                            selectionneNonValides: function() {
                                _($scope.gridSaisies).each(function(saisie, index) {
                                    if (saisie.valide === false) {
                                        $scope.grid.selectItem(index, true);
                                    }
                                });
                            },
                            populate: function(saisies) {
                                $scope.gridSaisies = $scope.filtre(saisies);
                                if (!$scope.montre_valides) {
                                    $scope.gridSaisies = _($scope.gridSaisies).where({valide: false});
                                }
                            }
                        };

                        // Graphiques
                        $scope.graphiques = {
                            pieChart: PIECHART_DEFINITION(),
                            barChart: BARCHART_DEFINITION(),
                            populate: function(data) {
                                $scope.graphiques.barChart.data = [];
                                $scope.graphiques.pieChart.data = [ { label: 'visas',
								      value: 0 },
								    { label: 'saisies',
								      value: 0 } ];
				
                                var saisies = {key: "saisies", values: []};
                                var valides = {key: "visas", values: []};

                                _.chain($scope.filtre(data))
                                        .groupBy('regroupement_id')
                                        .each(function(classe) {
                                            var filled = classe.length;
                                            var validated = _(classe).where({valide: true}).length;

                                            saisies.values.push([$scope.classes[ classe[0].regroupement_id ], filled]);
                                            valides.values.push([$scope.classes[ classe[0].regroupement_id ], validated]);

                                            $scope.graphiques.barChart.data = [valides, saisies];

                                            $scope.graphiques.pieChart.data[0].value += validated;
                                            $scope.graphiques.pieChart.data[1].value += filled - validated;
                                        });
                            }
                        };

                        $scope.process_data = function(  ) {
                            if ($scope.raw_data !== undefined) {
                                $scope.raw_data = _($scope.raw_data)
                                        .map(function(saisie, index) {
                                            // on référence l'index d'origine dans chaque élément pour propager la validation
                                            saisie.index = index;
                                            saisie.cours = new Cours(saisie.cours);
                                            // saisie.devoir = new Devoirs( saisie.devoir );
                                            return saisie;
                                        });

                                // consommation des données dans les graphiques et le grid
                                $scope.grid.populate($scope.raw_data);
                                $scope.graphiques.populate($scope.raw_data);
                            }
                        };

                        $scope.extract_matieres = function(saisies) {
                            var matieres = {};
                            _.chain(saisies)
                                    .flatten()
                                    .pluck('matiere_id')
                                    .uniq()
                                    .each(function(matiere_id) {
                                        Annuaire.get_matiere(matiere_id).$promise.then(
                                                function(response) {
                                                    matieres[ matiere_id ] = response.libelle_long;
                                                });
                                    });
                            return matieres;
                        };

                        $scope.extract_classes_promises = function(saisies) {
                            return _.chain(saisies)
                                    .flatten()
                                    .pluck('regroupement_id')
                                    .uniq()
                                    .map(function(regroupement_id) {
                                        return Annuaire.get_regroupement(regroupement_id);
                                    })
                                    .value();
                        };

                        User.get_user().success(function(response) {
                            $scope.current_user = response;
                            $scope.enseignant_id = $stateParams.enseignant_id;
                            if ($scope.enseignant_id === undefined && $scope.enseignant_id != $scope.current_user.uid) {
                                $scope.enseignant_id = $scope.current_user.uid;
                            }
                            
                            // Récupération et consommation des données
                            Annuaire.get_user($scope.enseignant_id)
                                    .$promise.then(
                                            function(response) {
                                                $scope.enseignant = response;
                                                // filtrer les classes de l'enseignnant sur l'établissement actif
                                                $scope.enseignant.matieres = _($scope.enseignant.classes).uniq(function(matiere) {
                                                    return matiere.matiere_enseignee_id;
                                                });
                                                $scope.enseignant.prof_principal = _.chain($scope.enseignant.classes)
                                                        .filter(function(matiere) {
                                                            return matiere.prof_principal == 'O';
                                                        })
                                                        .map(function(matiere) {
                                                            return matiere.classe_libelle;
                                                        })
                                                        .value();
                                            });

                            API.get_enseignant({ enseignant_id: $scope.enseignant_id,
                                uai: $scope.current_user['profil_actif']['uai'] })
                                    .$promise.then(
                                            function success(response) {
                                                $scope.raw_data = response.saisies;
                                                $scope.matieres = $scope.extract_matieres($scope.raw_data);
                                                // $q.all() permet d'attendre que tout les appels d' soient résolus avant de
                                                //   - remplir $scope.classes
                                                //   - puis d'appeler $scope.process_data() qui va pouvoir consommer $scope.classes
                                                //     pour passer les noms des classes aux graphiques qui ne peuvent pas profiter
                                                //     du data-binding d'angularJS car ils dessinent des canvas.
                                                $q.all($scope.extract_classes_promises($scope.raw_data))
                                                        .then(function(classes) {
                                                            _(classes).each(function(classe) {
                                                                $scope.classes[classe.id] = classe.libelle;
                                                            });
                                                            $scope.process_data();
                                                        });
                                            });
                        });
                    }]);
						$scope.enseignant.classes = _($scope.current_user.profil_actif.classes).uniq( function( classe ) { return classe.classe_libelle; });
