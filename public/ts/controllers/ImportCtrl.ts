'use strict';

angular.module('cahierDeTextesClientApp')
  .controller('ImportCtrl',
    ['$scope', '$http', '$locale', '$sce', '$filter', 'fileUpload', 'moment', 'toastr', '$q',
      'APP_PATH', 'SEMAINES_VACANCES', 'ZONE', 'VERSION',
      'Annuaire', 'Utils', 'Etablissements', 'CreneauxEmploiDuTemps', 'API', 'Matchable',
      'current_user',
      function($scope, $http, $locale, $sce, $filter, fileUpload, moment, toastr, $q,
        APP_PATH, SEMAINES_VACANCES, ZONE, VERSION,
        Annuaire, Utils, Etablissements, CreneauxEmploiDuTemps, API, Matchable,
        current_user) {
        let ctrl = $scope;
        ctrl.$ctrl = ctrl;

        ctrl.scope = ctrl;
        ctrl.jours_de_la_semaine = $locale.DATETIME_FORMATS.DAY;
        ctrl.annee = $locale.DATETIME_FORMATS.MONTH;
        ctrl.fichier = null;
        ctrl.display_all = false;
        ctrl.step = 0;
        ctrl.report = {};

        ctrl.ui = {
          show_detailed_creneaux: false,
          display_ready: true,
          display_problems: true,
          sortCreneauxBy: ['Jour'],
          sort_creneaux_by: function(criteria) {
            ctrl.ui.sortCreneauxBy = ctrl.ui.sortCreneauxBy[0] === criteria[0] ? _(criteria).map(function(sub_criteria) { return '-' + sub_criteria; }) : criteria;
          }
        };

        ctrl.step_backward = function() {
          ctrl.step--;
        }

        ctrl.beautify_semainier = function(semainier) {
          let bsemainier = Utils.padEnd(semainier.toString(2), 53, '0');

          return '<div class="semainier-tooltip gris1">' +
            _.chain(Utils.overlay_semainier())
              .sortBy(function(month) { return month.index; })
              .map(function(month) {
                let month_html = `<div class="month blanc"><h5 class="month-name gris4">${month.label}</h5>`;

                month_html += _(month.semaines).map(function(week) {
                  let week_html = '<span class="week';
                  if (Utils.sont_ce_les_vacances(week.semaine, ZONE)) { week_html += ' vacances gris2'; }
                  if (bsemainier[week.semaine] === '1') { week_html += ' active orange-moins'; }
                  week_html += `">${week.semaine}</span>`;

                  return week_html;
                }).join('');

                month_html += '</div>';

                return month_html;
              })
              .value()
              .join('') +
            '<div class="clearfix"></div></div>';
        };

        ctrl.filter_creneau = function(options, criteria) {
          return function(creneau) {
            if (!options.display_problems && !creneau.ready) { return false; }
            if (!options.display_ready && creneau.ready) { return false; }

            creneau.is_displayed = true;
            if (_(criteria.classes).isEmpty() && _(criteria.groupes).isEmpty()) {
              creneau.is_displayed = creneau.is_displayed &&
                !_(creneau).has('Classe') &&
                !_(creneau).has('Groupe');
            } else if (_(criteria.classes).isEmpty() && !_(criteria.groupes).isEmpty()) {
              creneau.is_displayed = creneau.is_displayed &&
                !_(creneau).has('Classe') &&
                _(creneau).has('Groupe') &&
                _.chain(criteria.groupes).pluck('Ident').includes(creneau.Groupe.Ident).value();
            } else if (!_(criteria.classes).isEmpty() && _(criteria.groupes).isEmpty()) {
              creneau.is_displayed = creneau.is_displayed &&
                _(creneau).has('Classe') &&
                !_(creneau).has('Groupe') &&
                _.chain(criteria.classes).pluck('Ident').includes(creneau.Classe.Ident).value();
            } else {
              creneau.is_displayed = creneau.is_displayed &&
                ((_(creneau).has('Groupe') && _.chain(criteria.groupes).pluck('Ident').includes(creneau.Groupe.Ident).value()) ||
                  (_(creneau).has('Classe') && _.chain(criteria.classes).pluck('Ident').includes(creneau.Classe.Ident).value()));
            }
            if (!creneau.is_displayed) {
              return false;
            }

            if (_(criteria.matieres).isEmpty()) {
              creneau.is_displayed = creneau.is_displayed && !_(creneau).has('Matiere');
            } else {
              creneau.is_displayed = creneau.is_displayed &&
                _(creneau).has('Matiere') &&
                _.chain(criteria.matieres).pluck('Ident').includes(creneau.Matiere.Ident).value();
            }
            if (!creneau.is_displayed) {
              return false;
            }

            return creneau.is_displayed;
          };
        };

        // ********** counters
        let update_counters = function() {
          let filtered_creneaux = $filter('filter')(ctrl.creneaux, ctrl.filter_creneau(ctrl.ui, ctrl.selected));
          ctrl.counters = {};

          ctrl.counters.creneaux = ctrl.creneaux.length;
          ctrl.counters.creneaux_broken = _(ctrl.pronote.Cours[0].Cours).select(function(cours) { return !_(cours).has('Matiere') || !_(cours).has('Professeur') || (!_(cours).has('Classe') && !_(cours).has('Groupe')); }).length;
          ctrl.counters.creneaux_not_ready = _(ctrl.creneaux).where({ ready: false }).length;
          ctrl.counters.creneaux_ready = ctrl.counters.creneaux - ctrl.counters.creneaux_not_ready;

          ctrl.counters.filtered_creneaux = filtered_creneaux.length;
          ctrl.counters.filtered_creneaux_not_ready = _(filtered_creneaux).where({ ready: false }).length;
          ctrl.counters.filtered_creneaux_ready = ctrl.counters.filtered_creneaux - ctrl.counters.filtered_creneaux_not_ready;

          ctrl.counters.percent_creneaux_ready = ctrl.counters.filtered_creneaux_ready / ctrl.counters.filtered_creneaux;
        };
        // ********** /counters

        // ********** readiness
        let update_creneaux_readiness = function() {
          _(ctrl.creneaux).each(function(creneau) {
            creneau.readiness = {
              matiere: !_(ctrl.pronote.matieres[creneau.Matiere.Ident]).isUndefined()
                && !_(ctrl.pronote.matieres[creneau.Matiere.Ident].laclasse).isUndefined(),
              salle: !_(creneau.Salle).isUndefined(),
              classe: _(creneau).has('Classe')
                && !_(ctrl.pronote.classes[creneau.Classe.Ident]).isUndefined()
                && !_(ctrl.pronote.classes[creneau.Classe.Ident].laclasse).isUndefined(),
              groupe_eleve: _(creneau).has('Groupe')
                && !_(ctrl.pronote.groupes_eleves[creneau.Groupe.Ident]).isUndefined()
                && !_(ctrl.pronote.groupes_eleves[creneau.Groupe.Ident].laclasse).isUndefined()
            };

            creneau.ready = creneau.readiness.matiere && (creneau.readiness.classe || creneau.readiness.groupe_eleve);
          });

          update_counters();
        };
        // ********** /readiness

        let hash_me = function(item) {
          let get_type = function(item) {
            if (_(item).has('PartieDeClass')) { return 'regroupement'; }
            else if (_(item).has('Code')) { return 'matiere'; }
            else { return 'unknown'; }
          };

          return window.btoa(unescape(encodeURIComponent(get_type(item) + item.displayed_label)));
        };

        // ACTIONS
        let decrypt_file = (fichier) => {
          ctrl.pronote = [];

          toastr.info('Déchiffrage du fichier');
          return fileUpload.uploadFileToUrl(fichier, `${APP_PATH}/api/import/pronote/decrypt`)
            .then(
              function success(response) {
                // 1. Récupérer le fichier Pronote décrypté
                ctrl.pronote = response.data;
                return $q.resolve(ctrl.pronote);
              });
        };

        let select_structure = () => {
          if (ctrl.pronote.Etablissements != undefined) {
            ctrl.etab_uai = ctrl.pronote.Etablissements[0].Etablissement[0].Numero;

            if (ctrl.pronote.Etablissements[0].Etablissement.length > 1) {
              return swal({
                title: 'Choisissez un établissement',
                input: 'select',
                inputOptions: _(ctrl.pronote.Etablissements[0].Etablissement.map((etab) => [etab.Numero, etab.Nom])).object(),
                inputPlaceholder: 'Choisissez un établissement',
                showCancelButton: false
              }).then(function(result) {
                ctrl.etab_uai = result.value;
                return $q.resolve(ctrl.etab_uai);
              })
            } else {
              return $q.resolve(ctrl.etab_uai);
            }
          } else {
            return $q.resolve(ctrl.pronote.UAI);
          }
        };

        let filter_structure = () => {
          let data = ctrl.pronote;

          if (ctrl.pronote.Etablissements != undefined && ctrl.pronote.Etablissements[0].Etablissement.length > 1) {
            toastr.info('Filtrage des données de l\'établissement sélectionné');
            let uai = ctrl.etab_uai;
            let etab_id = data.Etablissements[0].Etablissement.filter((etab) => etab.Numero == uai)[0].Ident;

            data.Classes[0].Classe = data.Classes[0].Classe.filter((classe) => classe.Etablissement.map((e) => e.Ident).includes(etab_id));
            let classes_ids = data.Classes[0].Classe.map((classe) => classe.Ident);
            let parties_de_classes_ids = _.flatten(data.Classes[0].Classe.map((classe) => classe.PartieDeClasse.map((pdc) => pdc.Ident)));

            data.Groupes[0].Groupe = data.Groupes[0].Groupe.filter((groupe) => _(groupe.PartieDeClasse.map((pdc) => pdc.Ident)).difference(parties_de_classes_ids).length == 0);
            let groupes_ids = data.Groupes[0].Groupe.map((groupe) => groupe.Ident);

            data.Cours[0].Cours = data.Cours[0].Cours.filter((creneau) => (creneau.Classe != undefined || creneau.Groupe != undefined || creneau.PartieDeClasse != undefined) && ((creneau.Classe != undefined && _.intersection(classes_ids, _(creneau.Classe).pluck("Ident")).length > 0) || (creneau.Groupe != undefined && _.intersection(groupes_ids, _(creneau.Groupe).pluck("Ident")).length > 0) || (creneau.PartieDeClasse != undefined && _.intersection(parties_de_classes_ids, _(creneau.PartieDeClasse).pluck("Ident")).length > 0)));

            ctrl.pronote = data;
          }

          return $q.resolve(data);
        };

        let load_data = () => {
          ctrl.matcheable_data = [];

          let handle_error = function(response) {
            return $q.reject(response);
          };

          ctrl.pronote.GrilleHoraire[0].DureePlace = parseInt(ctrl.pronote.GrilleHoraire[0].DureePlace);

          toastr.info('récupération des données de l\'établissement');
          // 2. Récupérer toutes les infos de l'établissement et toutes les matières
          return Etablissements.get({ uai: ctrl.pronote.UAI }).$promise
            .then(
              function success(response) {
                ctrl.etablissement_summary = response;
                _(ctrl.etablissement_summary.imports).each(function(i) { i.date_import = new Date(i.date_import); });

                return Annuaire.get_structure(ctrl.pronote.UAI);
              },
              handle_error
            )
            .then(
              function success(response) {
                ctrl.etablissement = {
                  classes: _(response.data.groups).where({ type: 'CLS' }),
                  groupes_eleves: _(response.data.groups).select(<any>{ type: 'GRP' })
                };

                _(ctrl.etablissement.groupes_eleves).each(function(regroupement) {
                  regroupement.libelle_aaf = regroupement.name.toUpperCase();
                  regroupement.displayed_label = regroupement.name;
                });
                _(ctrl.etablissement.classes).each(function(regroupement) {
                  regroupement.libelle_aaf = regroupement.name.toUpperCase();
                  regroupement.displayed_label = regroupement.name;
                });

                toastr.info('traitement des données des regroupements');
                // 3.3 Classes et Groupes
                return API.query_statistiques_regroupements(ctrl.pronote.UAI);
              },
              handle_error
            )
            .then(
              function success(response) {
                _(ctrl.pronote.Classes[0].Classe)
                  .each(function(regroupement) {
                    regroupement.displayed_label = regroupement.Nom;
                    regroupement.laclasse = _(ctrl.etablissement.classes).findWhere({ libelle_aaf: regroupement.Nom.toUpperCase() });

                    if (_(regroupement.laclasse).isUndefined()) {
                      let matched = _(ctrl.etablissement_summary.matchables).findWhere({ hash_item: hash_me(regroupement) });
                      if (!_(matched).isUndefined()) {
                        regroupement.laclasse = _(ctrl.etablissement.classes).findWhere({ id: matched.id_annuaire });
                      }
                    }

                    regroupement.edit = _(regroupement.laclasse).isUndefined();
                    let creneaux_laclasse = _(regroupement.laclasse).isUndefined() ? undefined : _(response.data).findWhere({ regroupement_id: "" + regroupement.laclasse.id });
                    regroupement.existing_creneaux = _(creneaux_laclasse).isUndefined() ? 0 : creneaux_laclasse.creneaux_emploi_du_temps.vides.length + creneaux_laclasse.creneaux_emploi_du_temps.pleins.length;

                    if (!regroupement.edit) {
                      regroupement.laclasse.displayed_label = regroupement.laclasse.libelle_aaf;
                    }
                  });

                _(ctrl.pronote.Groupes[0].Groupe)
                  .each(function(regroupement) {
                    regroupement.displayed_label = regroupement.Nom;
                    regroupement.laclasse = _(ctrl.etablissement.groupes_eleves).findWhere({ libelle_aaf: regroupement.Nom.toUpperCase() });

                    if (_(regroupement.laclasse).isUndefined()) {
                      let matched = _(ctrl.etablissement_summary.matchables).findWhere({ hash_item: hash_me(regroupement) });
                      if (!_(matched).isUndefined()) {
                        regroupement.laclasse = _(ctrl.etablissement.groupes_eleves).findWhere({ id: matched.id_annuaire });
                      }
                    }

                    regroupement.edit = _(regroupement.laclasse).isUndefined();
                    let creneaux_laclasse = _(regroupement.laclasse).isUndefined() ? undefined : _(response).findWhere({ regroupement_id: "" + regroupement.laclasse.id });
                    regroupement.existing_creneaux = _(creneaux_laclasse).isUndefined() ? 0 : creneaux_laclasse.creneaux_emploi_du_temps.vides.length + creneaux_laclasse.creneaux_emploi_du_temps.pleins.length;

                    if (!regroupement.edit) {
                      regroupement.laclasse.displayed_label = regroupement.laclasse.libelle_aaf;
                    }
                  });

                toastr.info('traitement des données des cours');
                // 4. treating Cours
                ctrl.creneaux = _.chain(ctrl.pronote.Cours[0].Cours)
                  .map(function(cours) {
                    return _.chain(cours.Matiere).map(function(matiere) {
                      let compute_cours = function(type_regroupement) {
                        return function(regroupement) {
                          let this_cours = angular.copy(cours);
                          this_cours.is_displayed = true;
                          this_cours.Matiere = matiere;

                          if (type_regroupement === 'Classe') {
                            this_cours.Classe = regroupement;
                            this_cours.Classe.Semaines = Utils.fix_semainier_pronote(this_cours.Classe.Semaines, ctrl.pronote.AnneeScolaire[0].DateDebut);
                          } else {
                            this_cours.Groupe = regroupement;
                            this_cours.Groupe.Semaines = Utils.fix_semainier_pronote(this_cours.Groupe.Semaines, ctrl.pronote.AnneeScolaire[0].DateDebut);
                          }

                          if (_(cours).has('Salle')) {
                            return _(cours.Salle).map(function(salle) {
                              this_cours.Salle = salle;
                              this_cours.Salle.Semaines = Utils.fix_semainier_pronote(this_cours.Salle.Semaines, ctrl.pronote.AnneeScolaire[0].DateDebut);

                              return this_cours;
                            });
                          } else {
                            return this_cours;
                          }
                        };
                      };

                      return [_(cours.Classe).map(compute_cours('Classe')),
                      _(cours.Groupe).map(compute_cours('Groupe'))];
                    })
                      .flatten()
                      .uniq()
                      .value();
                  })
                  .flatten()
                  .value();

                ctrl.pronote.classes = Utils.groupByKey(ctrl.pronote.Classes[0].Classe, 'Ident');
                ctrl.pronote.salles = Utils.groupByKey(ctrl.pronote.Salles[0].Salle, 'Ident');
                ctrl.pronote.plages_horaires = Utils.groupByKey(ctrl.pronote.GrilleHoraire[0].PlacesParJour[0].Place, 'Numero');
                ctrl.pronote.groupes_eleves = Utils.groupByKey(ctrl.pronote.Groupes[0].Groupe, 'Ident');

                ctrl.matcheable_data.push({
                  title: 'Classes',
                  pronote: ctrl.pronote.classes,
                  annuaire: ctrl.etablissement.classes
                });
                ctrl.matcheable_data.push({
                  title: 'Groupes d\'élèves',
                  pronote: ctrl.pronote.groupes_eleves,
                  annuaire: ctrl.etablissement.groupes_eleves
                });

                toastr.info('Récupération des matieres');
                // 3.1 Matières
                return Annuaire.query_subjects();
              },
              handle_error
            )
            .then(
              function success(response) {
                ctrl.matieres = _(response.data).map(function(matiere) {
                  if (_(matiere.name).isNull()) {
                    matiere.name = '';
                  }
                  matiere.name = matiere.name.toUpperCase();
                  matiere.displayed_label = matiere.name;

                  return matiere;
                });

                // 3. Matcher les 2
                _(ctrl.pronote.Matieres[0].Matiere)
                  .each(function(matiere) {
                    matiere.displayed_label = matiere.Libelle;
                    matiere.laclasse = _(ctrl.matieres).findWhere({ name: matiere.Libelle.toUpperCase() });

                    if (_(matiere.laclasse).isUndefined()) {

                      if (_(matiere.laclasse).isUndefined()) {
                        let matched = _(ctrl.etablissement_summary.matchables).findWhere({ hash_item: hash_me(matiere) });
                        if (!_(matched).isUndefined()) {
                          matiere.laclasse = _(ctrl.matieres).findWhere({ id: matched.id_annuaire });
                        }
                      }
                    }

                    matiere.edit = _(matiere.laclasse).isUndefined();
                    if (!matiere.edit) {
                      matiere.laclasse.displayed_label = matiere.laclasse.name;
                    }
                  });

                ctrl.pronote.matieres = Utils.groupByKey(ctrl.pronote.Matieres[0].Matiere, 'Ident');
                ctrl.matcheable_data.push({
                  title: 'Matières',
                  pronote: ctrl.pronote.matieres,
                  annuaire: ctrl.matieres
                });

                _(ctrl.matcheable_data).each(function(dataset) {
                  dataset.total = function() { return _(dataset.pronote).size(); };
                  dataset.unmatched = function() { return _(dataset.pronote).where({ laclasse: undefined }).length; };
                  dataset.percent_valid = function() { return (dataset.total() - dataset.unmatched()) / dataset.total(); };
                });

                ctrl.selected = {
                  matieres: ctrl.pronote.Matieres[0].Matiere,
                  classes: _(ctrl.pronote.Classes[0].Classe).where({ existing_creneaux: 0 }),
                  groupes: _(ctrl.pronote.Groupes[0].Groupe).where({ existing_creneaux: 0 })
                };

                update_creneaux_readiness();

                ctrl.$watchCollection('selected', function() { update_counters(); });
              },
              handle_error
            )
            .then(
              function success(response) {
                ctrl.step++;
                return $q.resolve(true);
              },
              handle_error
            );
        };

        ctrl.process_load = function(fichier) {
          swal({
            title: "Déchiffrage du fichier...",
            text: "traitement en cours",
            type: "info",
            showLoaderOnConfirm: true,
            onOpen: function() {
              swal.clickConfirm();
            },
            preConfirm: function() {
              return new Promise(function(resolve) {
                decrypt_file(fichier)
                  .then(select_structure)
                  .then(filter_structure)
                  .then(load_data)
                  .then(() => { swal.closeModal(); },
                    (response) => {
                      swal.closeModal();
                      swal({
                        title: 'Erreur :(',
                        text: response.data.error,
                        type: 'error'
                      });

                    }
                  );
              });
            },
            allowOutsideClick: false
          });
        };

        let import_data = function() {
          let started_at = moment();
          let import_id = null;

          let handle_error = function(response) {
            return $q.reject(response);
          };

          ctrl.report = {};

          let creneaux_emploi_du_temps = _(ctrl.creneaux).select(function(creneau) {
            return creneau.ready && creneau.is_displayed;
          });

          // Log import
          return $http.post(`${APP_PATH}/api/import/log/start/?uai=${ctrl.pronote.UAI}`, { uai: ctrl.pronote.UAI, type: 'client ' + VERSION, comment: '' })
            .then(
              function success(response) {
                import_id = response.data.id;

                // Create Etablissement
                let ct_etablissement = new Etablissements({
                  uai: ctrl.pronote.UAI,
                  date_premier_jour_premiere_semaine: new Date(ctrl.pronote.AnneeScolaire[0].DatePremierJourSemaine1),
                  debut_annee_scolaire: new Date(ctrl.pronote.AnneeScolaire[0].DateDebut),
                  fin_annee_scolaire: new Date(ctrl.pronote.AnneeScolaire[0].DateFin)
                });
                return ct_etablissement.$save();
              },
              handle_error
            )
            .then(
              function success(response) {
                ctrl.report.etablissement = response;

                // Create CahierDeTextes
                let preprocess_cahiers_de_textes = function(liste_regroupements) {
                  return _.chain(liste_regroupements)
                    .reject(function(regroupement) { return _(regroupement.laclasse).isUndefined(); })
                    .map(function(regroupement) {
                      return {
                        label: regroupement.laclasse.libelle_aaf,
                        regroupement_id: regroupement.laclasse.id,
                        debut_annee_scolaire: new Date(ctrl.pronote.AnneeScolaire[0].DateDebut),
                        fin_annee_scolaire: new Date(ctrl.pronote.AnneeScolaire[0].DateFin)
                      };
                    })
                    .value();
                };
                let regroupements = preprocess_cahiers_de_textes(ctrl.pronote.classes);

                regroupements.push(preprocess_cahiers_de_textes(ctrl.pronote.groupes_eleves));
                regroupements = _(regroupements).flatten();

                return $http.post(`${APP_PATH}/api/cahiers_de_textes/bulk`, { cahiers_de_textes: regroupements });
              },
              handle_error
            )
            .then(
              function success(response) {
                ctrl.report.cahiers_de_textes = response.data;

                // Create Salle
                toastr.info('Création des salles');
                let salles_to_import = _(ctrl.pronote.salles)
                  .map(function(salle) {
                    return {
                      uai: ctrl.pronote.UAI,
                      identifiant: salle.Ident,
                      nom: salle.Nom
                    };
                  });

                return $http.post(`${APP_PATH}/api/salles/bulk`, { salles: salles_to_import });
              },
              handle_error
            )
            .then(
              function success(response) {
                ctrl.report.salles = response.data;

                // Create Creneaux
                let creneaux_to_import = creneaux_emploi_du_temps.map(function(creneau) {
                  let heure_debut = Utils.libelleHeure_to_Moment(ctrl.pronote.plages_horaires[creneau.NumeroPlaceDebut].LibelleHeureDebut);

                  let pre_creneau = {
                    import_id: import_id,
                    jour_de_la_semaine: parseInt(creneau.Jour),
                    heure_debut: heure_debut.toISOString(),
                    heure_fin: heure_debut.add(parseInt(creneau.NombrePlaces) * parseInt(ctrl.pronote.GrilleHoraire[0].DureePlace), 'minutes').toISOString(),
                    matiere_id: ctrl.pronote.matieres[creneau.Matiere.Ident].laclasse.id,
                    salle_id: null,
                    semainier_salle: null,
                    regroupement_id: null,
                    semainier_regroupement: null
                  };

                  if (_(creneau).has('Salle')) {
                    pre_creneau.salle_id = _(ctrl.report.salles).find({ identifiant: creneau.Salle.Ident }).id;
                    pre_creneau.semainier_salle = parseInt(creneau.Salle.Semaines);
                  }

                  if (_(creneau).has('Classe')) {
                    pre_creneau.regroupement_id = ctrl.pronote.classes[creneau.Classe.Ident].laclasse.id;
                    pre_creneau.semainier_regroupement = parseInt(creneau.Classe.Semaines);
                  } else {
                    pre_creneau.regroupement_id = ctrl.pronote.groupes_eleves[creneau.Groupe.Ident].laclasse.id;
                    pre_creneau.semainier_regroupement = parseInt(creneau.Groupe.Semaines);
                  }

                  return pre_creneau;
                });

                toastr.info(`Import de ${creneaux_to_import.length} créneaux`);

                let promises = [];
                while (creneaux_to_import.length > 0) {
                  promises.push($http.post(`${APP_PATH}/api/creneaux_emploi_du_temps/bulk/`,
                    {
                    uai: ctrl.pronote.UAI,
                    creneaux_emploi_du_temps: creneaux_to_import.splice(0, 500)
                    }));
                }

                return $q.all(promises);
              },
              handle_error
            )
            .then(
              function success(response) {
                ctrl.report.creneaux = _.chain(response).pluck('data').flatten().value();

                return $q.resolve(ctrl.report);
              },
              handle_error
            );
        };

        ctrl.match_this = function(item, uai) {
          let laclasse_id = _(item.laclasse).has('ent_id') ? item.laclasse.ent_id : item.laclasse.id;

          let m = new Matchable({
            uai: uai,
            hash_item: hash_me(item),
            id_annuaire: laclasse_id
          });
          m.$save().then(function() {
            update_creneaux_readiness();
          });
        };
        // FIXME
        ctrl.unmatch_this = function(item, uai) {
          Matchable.delete({
            uai: uai,
            hash_item: hash_me(item)
          }).$promise
            .then(function() {
              item.laclasse = null;
              update_creneaux_readiness();
            });
        };

        ctrl.validate_matches = function() {
          ctrl.step++;
        };

        ctrl.process_import = function() {
          swal({
            title: "Import des données...",
            text: "traitement en cours",
            type: "info",
            showLoaderOnConfirm: true,
            allowOutsideClick: false,
            onOpen: function() {
              swal.clickConfirm();
            },
            preConfirm: function() {
              return new Promise(function(resolve) {
                import_data().then(
                  function success(response) {
                    swal.closeModal();
                    ctrl.step = 0;
                    swal({
                      title: "Import terminé",
                      html: "",
                      type: 'success'
                    });
                  },
                  function error(response) {
                    swal.closeModal();
                    swal({
                      title: 'Erreur :(',
                      text: response.data.error,
                      type: 'error'
                    });
                  }
                );
              });
            }
          });
        };
      }]);
