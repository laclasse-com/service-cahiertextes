'use strict';

angular.module('cahierDeTextesClientApp')
  .controller('PopupEditionCtrl',
    ['$scope', '$filter', '$q', '$sce', '$uibModalInstance', '$locale', 'toastr', 'moment',
      'APP_PATH', 'URL_DOCS', 'SEMAINES_VACANCES', 'ZONE', 'POPUP_ACTIONS', 'LOCALHOST',
      'Documents', 'API', 'CreneauxEmploiDuTemps', 'Cours', 'Devoirs', 'CurrentUser', 'Utils',
     'cours', 'devoirs', 'creneau', 'raw_data', 'classes', 'matieres',
     function($scope, $filter, $q, $sce, $uibModalInstance, $locale, toastr, moment,
              APP_PATH, URL_DOCS, SEMAINES_VACANCES, ZONE, POPUP_ACTIONS, LOCALHOST,
        Documents, API, CreneauxEmploiDuTemps, Cours, Devoirs, CurrentUser, Utils,
              cours, devoirs, creneau, raw_data, classes, matieres) {
       let ctrl = $scope;
       ctrl.scope = ctrl;

       ctrl.correctTimeZoneToGMT = function(date) {
         let timezoneOffset = new Date(date).getTimezoneOffset() / 60;
         date.setHours(date.getHours() + timezoneOffset);

         return date;
       };

       ctrl.app_path = APP_PATH;
       ctrl.ZONE = ZONE;
       ctrl.jours = _($locale.DATETIME_FORMATS.DAY).indexBy(function(jour) { return _($locale.DATETIME_FORMATS.DAY).indexOf(jour); });
       ctrl.classes = classes;
       ctrl.matieres = _(matieres).sortBy('name');

       ctrl.faulty_docs_app = false;
       ctrl.erreurs = [];
       ctrl.dirty = false;
       ctrl.mode_duplication = false;
       ctrl.actions_done = [];

       ctrl.creneau = creneau;
       ctrl.creneau.jour_de_la_semaine = '' + ctrl.creneau.jour_de_la_semaine;
       ctrl.mode_edition_creneau = ctrl.creneau.en_creation;
       ctrl.creneau.regroupement_id = parseInt(ctrl.creneau.regroupement_id);
       ctrl.creneau.previous_regroupement_id = ctrl.creneau.regroupement_id;
       ctrl.selected_regroupement = _(ctrl.creneau.regroupement_id).isUndefined() ? _(ctrl.classes).first() : _(ctrl.classes).findWhere({ id: parseInt(ctrl.creneau.regroupement_id) });
       ctrl.selected_matiere = _(ctrl.creneau.matiere_id).isEmpty() ? _(ctrl.matieres).first() : _(ctrl.matieres).findWhere({ id: ctrl.creneau.matiere_id });
       if (ctrl.creneau.en_creation) {
         ctrl.creneau.tmp_heure_debut = ctrl.correctTimeZoneToGMT(ctrl.creneau.heure_debut);
         ctrl.creneau.tmp_heure_fin = ctrl.correctTimeZoneToGMT(ctrl.creneau.heure_fin);
       } else {
         ctrl.creneau.tmp_heure_debut = angular.copy(ctrl.creneau.heure_debut);
         ctrl.creneau.tmp_heure_fin = angular.copy(ctrl.creneau.heure_fin);

         _(ctrl.creneau.regroupements).each(function(regroupement) {
           regroupement.regroupement_id = parseInt(regroupement.regroupement_id);
         });
       }
       ctrl.creneau.tmp_heure_debut = moment(ctrl.creneau.tmp_heure_debut);
       ctrl.creneau.tmp_heure_fin = moment(ctrl.creneau.tmp_heure_fin);
       ctrl.creneau.n_week = moment(ctrl.creneau.tmp_heure_debut).week();

       let do_nothing = function() { };

       ctrl.formateCreneau = function(creneau) {
         let label = '';

         if (_(creneau).has('start')) {
           label += `${$filter('amDateFormat')(creneau.start, 'ddd DD MMM HH:mm')} - ${$filter('amDateFormat')(creneau.end, 'HH:mm')}`;
         } else {
           label += `${$filter('amDateFormat')(creneau.heure_debut, 'ddd DD MMM HH:mm')} - ${$filter('amDateFormat')(creneau.heure_fin, 'HH:mm')}`;
         }

         return label;
       };

       ctrl.correctTimeZone = function(date) {
         date = new Date(date);
         let timezoneOffset = date.getTimezoneOffset() / 60;
         date.setHours(date.getHours() - timezoneOffset);

         return date;
       };

       let create_cours = function(creneau) {
         let cours = new Cours({
           creneau_emploi_du_temps_id: creneau.id,
           date_cours: new Date(creneau.heure_debut).toISOString(),
           date_validation: null,
           enseignant_id: ctrl.current_user.id,
           contenu: ''
         });
         cours.devoirs = [];
         cours.create = true;

         return cours;
       };

       ctrl.is_dirty = function(item) {
         item = _(item).isUndefined() || _(item).isNull() ? null : item;
         ctrl.dirty = ctrl.dirty || (_(item).isNull() || (!_(item).isNull() && item.contenu.length > 0));
         if (!_(item).isNull()) {
           item.dirty = true;
         }
       };

       // Initialisations {{{

       // Gestion des semaines actives
       ctrl.overlay_semainier = Utils.overlay_semainier();

       ctrl.sont_ce_les_vacances = Utils.sont_ce_les_vacances;

       let semaines_toutes_actives = function() {
         let semainier = [];
         _(52).times(function(i) {
           if (!Utils.sont_ce_les_vacances(i + 1, ZONE)) {
             semainier.push(1);
           } else {
             semainier.push(0);
           }
         });

         return semainier;
       };

       ctrl.semaines_actives = { regroupement: [] };
       ctrl.templates_semainier = [
         {
           label: 'Tout',
           apply: function() {
             ctrl.semaines_actives.regroupement = semaines_toutes_actives();
           }
         },
         {
           label: 'Semaine A',
           apply: function() {
             let template = [];
             let semaines_depuis_les_vacances = 0;
             _(52).times(function(i) {
               if (Utils.sont_ce_les_vacances(i + 1, ZONE)) {
                 semaines_depuis_les_vacances = 0;
               } else {
                 semaines_depuis_les_vacances++;
               }
               template.push((semaines_depuis_les_vacances % 2 == 1) ? 1 : 0);
             });
             ctrl.semaines_actives.regroupement = template;
           }
         },
         {
           label: 'Semaine B',
           apply: function() {
             let template = [];
             let semaines_depuis_les_vacances = 0;
             _(52).times(function(i) {
               if (Utils.sont_ce_les_vacances(i + 1, ZONE)) {
                 semaines_depuis_les_vacances = 0;
               } else {
                 semaines_depuis_les_vacances++;
               }
               template.push((semaines_depuis_les_vacances % 2 == 0) ? 1 : 0);
             });
             ctrl.semaines_actives.regroupement = template;
           }
         },
         {
           label: 'Unique',
           apply: function() {
             let template = [];
             _(52).times(function(week) {
               template.push((week + 1 == ctrl.creneau.n_week) ? 1 : 0);
             });
             ctrl.semaines_actives.regroupement = template;
           }
         },
         {
           label: 'Inverser',
           apply: function() {
             ctrl.semaines_actives.regroupement = _(ctrl.semaines_actives.regroupement).map(function(w, i) {
               return ((w == 0) && !Utils.sont_ce_les_vacances(i + 1, ZONE)) ? 1 : 0;
             });
           }
         },
         {
           label: 'Réinitialiser',
           apply: function() {
             ctrl.semaines_actives.regroupement = ctrl.creneau.en_creation ? semaines_toutes_actives() : Utils.fixnum_to_bitfield(creneau.semainier);
           }
         }
       ];
       _(ctrl.templates_semainier).findWhere({ label: 'Réinitialiser' }).apply();

       // helpers
       ctrl.fermer = function() {
         if (ctrl.cours && ctrl.cours.deleted) {
           Documents.rm(_(ctrl.cours.ressources).pluck('hash'));
         }

         let clean_ressources_devoirs = function(devoirs) {
           if (devoirs) {
             _.chain(devoirs)
               .where({ deleted: true })
               .each(function(devoir) {
                 Documents.rm(_(devoir.ressources).pluck('hash'));
               });
           }
         }

         if (ctrl.cours) {
           clean_ressources_devoirs(ctrl.cours.devoirs);
         }
         if (ctrl.devoirs) {
           clean_ressources_devoirs(ctrl.devoirs);
         }

         $uibModalInstance.close(ctrl);
       };

       ctrl.effacer_creneau = function() {
         let do_it = function() {
           CreneauxEmploiDuTemps.delete({
             id: ctrl.creneau.id,
             date_creneau: ctrl.creneau.heure_debut
           })
             .$promise.then(function() {
               ctrl.actions_done.push(POPUP_ACTIONS.CRENEAU_DELETED);
               ctrl.fermer();
             });
         };

         if (ctrl.dirty) {
           swal({
             title: 'Ceci supprimera le créneau à compter du ' + $filter('amDateFormat')(creneau.heure_debut, 'dddd D MMMM YYYY'),
             text: 'Le créneau avec ses séquences pédagogiques et devoirs associés restera visible pour les dates antérieures.',
             type: 'warning',
             showCancelButton: true,
             confirmButtonColor: '#ff6b55',
             confirmButtonText: 'Confirmer',
             cancelButtonText: 'Annuler'
           }).then(do_it,
                   do_nothing);
         } else {
           do_it();
         }
       };

       ctrl.annuler = function() {
         let do_it = function() {
           if (ctrl.creneau.en_creation) {
             ctrl.effacer_creneau();
           } else {
             ctrl.dirty = false;
             if (ctrl.actions_done.length == 0) {
               ctrl.actions_done.push(POPUP_ACTIONS.CANCELLED);
             }
             ctrl.fermer();
           }
         };
         if (ctrl.dirty) {
           swal({
             title: 'Êtes-vous sur ?',
             text: 'Les modifications que vous avez faites dans cette fenêtre seront perdues.',
             type: 'warning',
             showCancelButton: true,
             confirmButtonColor: '#ff6b55',
             confirmButtonText: 'Confirmer',
             cancelButtonText: 'Annuler'
           }).then(do_it,
                   do_nothing);
         } else {
           do_it();
         }
       };

       ctrl.valider = function() {
         // réinitialisation des erreurs
         ctrl.erreurs = [];
         let promesses = [];

         if (ctrl.mode_edition_creneau) {
           ctrl.creneau.matiere_id = ctrl.selected_matiere.id;
           ctrl.creneau.regroupement_id = ctrl.selected_regroupement.id;
           if (ctrl.creneau.tmp_heure_debut > ctrl.creneau.tmp_heure_fin) {
             let tmp = ctrl.creneau.tmp_heure_debut;
             ctrl.creneau.tmp_heure_debut = ctrl.creneau.tmp_heure_fin;
             ctrl.creneau.tmp_heure_fin = tmp;
           }
           ctrl.creneau.heure_debut = ctrl.correctTimeZone(ctrl.creneau.tmp_heure_debut);
           ctrl.creneau.heure_fin = ctrl.correctTimeZone(ctrl.creneau.tmp_heure_fin);
           ctrl.creneau.semainier_regroupement = Utils.bitfield_to_fixnum(ctrl.semaines_actives.regroupement);

           ctrl.creneau.$update();

           ctrl.actions_done.push(POPUP_ACTIONS.CRENEAU_MODIFIED);
         } else {
           // Gestion des Cours et Devoirs
           let valider_devoirs = function(devoirs, cours) {
             _.chain(devoirs)
               .where({ dirty: true })
               .each(function(devoir) {
                 let prom = $q.defer();
                 let treat_error = function error(response) {
                   ctrl.erreurs.unshift({
                     status: response.status,
                     message: response.data.error
                   });
                   prom.reject(response);
                 };
                 let treat_success = function(action) {
                   return function success(result) {
                     devoir.id = result.id;
                     prom.resolve(result);
                     ctrl.actions_done.push(action);
                   };
                 };

                 if (devoir.create) {
                   devoir.regroupement_id = ctrl.selected_regroupement.id;
                   if (!_(cours).isNull()) { devoir.cours_id = cours.id; }
                   if (!_(devoir).has('contenu')) { devoir.contenu = ''; }

                   devoir.$save().then(treat_success(POPUP_ACTIONS.DEVOIR_CREATED),
                                       treat_error);
                 } else {
                   devoir.$update().then(treat_success(POPUP_ACTIONS.DEVOIR_MODIFIED),
                                         treat_error);
                 }

                 promesses.push(prom.promise);
               });
           };

           // Séquence Pédogogique du créneau
           if ((ctrl.cours.contenu.length > 0 || (_(ctrl.cours).has('ressources') && ctrl.cours.ressources.length > 0)) || (ctrl.cours.devoirs.length > 0)) {
             let cours_devoirs = _(ctrl.cours.devoirs).map(function(devoir) {
               return new Devoirs(devoir);
             });

             if (ctrl.cours.editable) {
               let promesse = $q.when(true);

               if (ctrl.cours.create) {
                 ctrl.cours.regroupement_id = ctrl.selected_regroupement.id;
                 ctrl.cours.creneau_emploi_du_temps_id = ctrl.creneau.id;
                 promesse = ctrl.cours.$save();
                 ctrl.actions_done.push(POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_CREATED);
               } else {
                 promesse = ctrl.cours.$update();
                 ctrl.actions_done.push(POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_MODIFIED);
               }

               // Devoirs liés au cours
               if (cours_devoirs.length > 0) {
                 promesse.then(function(cours_from_DB) {
                   valider_devoirs(cours_devoirs, cours_from_DB);
                 });
               }
             } else {
               valider_devoirs(cours_devoirs, ctrl.cours);
             }
           }

           // Devoirs dûs ce créneau
           valider_devoirs(ctrl.devoirs, null);
         }

         $q.all(promesses).then(ctrl.fermer);
       };





       // Gestion des Cours et Devoirs ///////////////////////////////////////////////////////////////////////////
       let init_cours_existant = function(cours) { };

       if (!ctrl.creneau.en_creation) {
         // fonctions UI pour le temps estimé
         ctrl.estimation_over = function(d, value) {
           d.overValue = value;
           d.minutes = 5 * value;
         };
         ctrl.estimation_leave = function(d) {
           ctrl.estimation_over(d, d.temps_estime);
         };

         API.query_types_de_devoir()
           .then(function(response) {
             ctrl.types_de_devoir = response.data;
           });

         init_cours_existant = function(cours) {
           ctrl.cours = Cours.get({ id: cours.id });
           // ctrl.cours = new Cours( cours );

           ctrl.cours.$promise.then(function(cours) {
             ctrl.cours.editable = _(ctrl.cours.date_validation).isNull() && ctrl.current_user.is(['ENS', 'DOC']) && ctrl.cours.enseignant_id === ctrl.current_user.id;
             if (!ctrl.cours.editable) {
               ctrl.cours.contenu = $sce.trustAsHtml(ctrl.cours.contenu);
             }

             cours.devoirs = _.chain(cours.devoirs)
               .select(function(devoir) {
                 return _(devoirs).findWhere({ id: devoir.id }) == undefined;
               })
               .map(function(devoir) {
                 return Devoirs.get({ id: devoir.id });
               })
               .value();

             _(cours.devoirs).each(function(devoir) {
               devoir.$promise.then(function(d) {
                 ctrl.estimation_leave(d);
                 d.tooltip = `<em>${$filter('amDateFormat')(d.date_due, 'dddd D MMMM YYYY')}</em><hr />${d.contenu}`;
                 if (d.temps_estime > 0) {
                   d.tooltip = `<span><i class="picto temps"></i>${d.temps_estime * 5} minutes</span><hr />${d.tooltip}`;
                 }
                 d.tooltip = $sce.trustAsHtml(`<div>${d.tooltip}</div>`);

                 if (ctrl.creneau.etranger) {
                   d.contenu = $sce.trustAsHtml(d.contenu);
                 }
               });
             });

             $q.all(ctrl.devoirs).then(function() {
               ctrl.cours.devoirs = _(ctrl.cours.devoirs).filter(function(devoir) {
                 return _(ctrl.devoirs).findWhere({ id: devoir.id }) == undefined;
               });
             });

             ctrl.cours.$promise.then(function() {
               _(ctrl.cours.ressources).each(function(ressource) {
                 ressource.url = $sce.trustAsResourceUrl(`${URL_DOCS}/api/connector?cmd=file&target=${ressource.hash}`);
               });
             });
             _(ctrl.cours.devoirs).each(function(devoir) {
               devoir.$promise.then(function() {
                 _(devoir.ressources).each(function(ressource) {
                   ressource.url = $sce.trustAsResourceUrl(`${URL_DOCS}/api/connector?cmd=file&target=${ressource.hash}`);
                 });
               });
             });

           });
           ctrl.cours.create = false;
         };

         ctrl.devoirs = devoirs.map(function(devoir) {
           let devoir_from_DB = Devoirs.get({ id: devoir.id });
           // devoir_from_DB.$promise.then( function( d ) {
           //     d.cours.tooltip = $sce.trustAsHtml( "<div><em>" + $filter('amDateFormat')( d.cours.date_cours, 'dddd D MMMM YYYY' ) + "</em><hr />" + d.cours.contenu + "</div>" );
           // } );

           return devoir_from_DB;
         });

         _(ctrl.devoirs).each(function(devoir) {
           devoir.$promise.then(function() {
             ctrl.estimation_leave(devoir);
             _(devoir.ressources).each(function(ressource) {
               ressource.url = $sce.trustAsResourceUrl(`${URL_DOCS}/api/connector?cmd=file&target=${ressource.hash}`);
             });
             if (ctrl.creneau.etranger) {
               devoir.contenu = $sce.trustAsHtml(devoir.contenu);
             }
           });
         });

         // Fonction UI pour fixer l'id du créneau en fct du choix dans la sbox des créneaux possibles.
         ctrl.set_creneau_date_due = function(devoir) {
           // on prend le premier créneau qui correspond à cette date.
           let creneau_choisi = _(ctrl.creneaux_devoirs_possibles).findWhere({
             date_due: devoir.date_due
           });
           devoir.creneau_emploi_du_temps_id = creneau_choisi.id;
           ctrl.is_dirty(devoir);
         };

         let liste_creneaux_similaires = function(creneau, n_semaines_before, n_semaines_after) {
           return API.get_creneaux_emploi_du_temps_similaires({
             id: creneau.id,
             debut: moment(creneau.heure_debut.toISOString()).subtract(n_semaines_before, 'weeks').toDate(),
             fin: moment(creneau.heure_debut.toISOString()).add(n_semaines_after, 'weeks').toDate()
           });
         };

         liste_creneaux_similaires(ctrl.creneau, 2, 8)
           .then(function(response) {
             ctrl.creneaux_devoirs_possibles_duplication = [];
             ctrl.creneaux_similaires = _.chain(response.data)
               .reject(function(creneau) { return _(creneau.regroupement_id).isUndefined() || creneau.has_cours; })
               .map(function(creneau) {
                 creneau.classe = _(ctrl.classes).findWhere({ id: parseInt(creneau.regroupement_id) });
                 creneau.heure_debut = new Date(creneau.heure_debut);
                 creneau.heure_fin = new Date(creneau.heure_fin);

                 return creneau;
               })
               .value();
             ctrl.creneaux_similaires.selected = [];
           });

         liste_creneaux_similaires(ctrl.creneau, 0, 8)
           .then(function(response) {
             if (_(response.data).isEmpty()) {
               response.data = [ctrl.creneau];
             }
             ctrl.creneaux_devoirs_possibles = _.chain(response.data)
               .select(function(creneau) { return creneau.regroupement_id === ctrl.creneau.regroupement_id; })
               .map(function(creneau) {
                 creneau.classe = _(ctrl.classes).findWhere({ id: parseInt(creneau.regroupement_id) });
                 creneau.semaine = moment(creneau.start).from(moment(ctrl.creneau.heure_debut));
                 creneau.heure_debut = new Date(creneau.heure_debut);
                 creneau.heure_fin = new Date(creneau.heure_fin);
                 creneau.date_due = $filter('date')(creneau.heure_debut, 'y-MM-dd');

                 return creneau;
               })
               .sortBy(function(creneau) { // Trie par dates croissantes
                 return creneau.start;
               })
               .value();
             if (ctrl.creneaux_devoirs_possibles.length > 1) {
               ctrl.creneaux_devoirs_possibles = _(ctrl.creneaux_devoirs_possibles)
                 .select(function(creneau) {
                   return creneau.heure_debut.toISOString() != ctrl.creneau.heure_debut.toISOString();
                 });
             }
           });

         // {{{ Gestion des documents attachés
         ctrl.cartable = {};
         ctrl.cartable.expandedNodes = [];
         ctrl.treeOptions = {
           dirSelectable: false
         };

         Documents.list_files()
           .then(function(response) {
             if (_(response.data).has('files')) {
               ctrl.cartable = response.data;
               ctrl.cartable.files = _(response.data.files).select(function(file) {
                 return _(file.phash).isNull();
               });
               ctrl.cartable.expandedNodes = [];
             }
           },
                 function error() { }
                );

         ctrl.consume_Documents_response_callback = function(item) {
           return function(response) {
             ctrl.erreurs = [];
             if (!_(response.error).isEmpty()) {
               ctrl.erreurs.push({ message: response.error });
             } else {
               let _item = _(response.added).first();
               item.ressources.push({
                 name: _item.name,
                 hash: _item.hash,
                 url: $sce.trustAsResourceUrl(`${URL_DOCS}/api/connector?cmd=file&target=${_item.hash}`)
               });
               ctrl.is_dirty(item);

               if (!_(response.removed).isEmpty()) {
                 item.ressources = _(item.ressources).reject(function(ressource) {
                   return _(response.removed).includes(ressource.hash);
                 });
               }
             }
           };
         };

         ctrl.upload_and_add_ressource = function(item, fichiers) {
           if (item.ressources == undefined) {
             item.ressources = [];
           }
           Documents.upload_dans_cahier_de_textes(ctrl.selected_regroupement, fichiers)
             .then(function success(responses) {
               responses.forEach(function(response) {
                 ctrl.consume_Documents_response_callback(item)(response.data);
               });
             });
         };

         ctrl.remove_ressource = function(item, hash) {
           Documents.rm([hash]);
           item.ressources = _(item.ressources).reject(function(ressource) {
             return ressource.hash == hash;
           });
           ctrl.is_dirty(item);
         };
         // }}}

         ctrl.effacer_cours = function() {
           ctrl.cours.$delete()
             .then(function() {
               ctrl.actions_done.push(POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_DELETED);
               init_cours_existant(ctrl.cours);
             });
         };

         ctrl.effacer_devoir = function(devoir) {
           if (_(devoir).has('id')) {
             devoir.$delete().then(function() {
               ctrl.actions_done.push(POPUP_ACTIONS.DEVOIR_DELETED);
             });
           } else {
             devoir.deleted = true;
           }
         };

         // fonctions d'événements GUI {{{
         ctrl.ajout_devoir = function(where, creneau_cible) {
           if (_(creneau_cible).isNull() || _(creneau_cible).isUndefined() || ctrl.creneaux_devoirs_possibles.length < 1) {
             creneau_cible = ctrl.creneau;
           } else if (creneau_cible === 'next') {
             if (ctrl.creneaux_devoirs_possibles.length > 1) {
               creneau_cible = _.chain(ctrl.creneaux_devoirs_possibles)
                 .select(function(creneau) {
                   return creneau.heure_debut > ctrl.creneau.heure_debut;
                 })
                 .head()
                 .value();
             } else {
               creneau_cible = _(ctrl.creneaux_devoirs_possibles).first();
             }
           }

           let devoir = new Devoirs({
             cours_id: ctrl.cours.id,
             date_due: $filter('date')(creneau_cible.heure_debut, 'yyyy-MM-dd'),
             type_devoir_id: _(ctrl.types_de_devoir).last().id,
             creneau_emploi_du_temps_id: creneau_cible.id,
             contenu: ''
           });
           devoir.create = true;
           devoir.dirty = true;

           where.unshift(devoir);
         };

         // {{{ duplication
         ctrl.switch_to_duplication_mode = function() {
           ctrl.mode_duplication = true;
         };

         ctrl.ok_go_for_duplication = false;
         ctrl.are_we_go_for_duplication = function() {
           ctrl.ok_go_for_duplication = !_(ctrl.creneaux_similaires.selected).isEmpty()
             && _(ctrl.cours.devoirs).reduce(function(is_it, devoir) { return is_it && _(devoir).has('creneau_cible'); }, true);
         };

         ctrl.creneau_cible_duplication_SP_updated = function() {
           // Calcul des créneaux cibles pour les devoirs
           liste_creneaux_similaires(ctrl.creneaux_similaires.selected, 0, 4)
             .then(function(response) {
               ctrl.creneaux_devoirs_possibles_duplication = _.chain(response.data)
                 .select(function(creneau) { return creneau.regroupement_id == ctrl.creneaux_similaires.selected.regroupement_id; })
                 .map(function(creneau) {
                   creneau.classe = _(ctrl.classes).findWhere({ id: parseInt(creneau.regroupement_id) });
                   creneau.date_due = $filter('date')(creneau.start, 'y-MM-dd');
                   creneau.semaine = `${moment(creneau.start).from(moment(ctrl.creneau.heure_debut), true)} plus tard`;
                   creneau.heure_debut = new Date(creneau.heure_debut);
                   creneau.heure_fin = new Date(creneau.heure_fin);

                   return creneau;
                 })
                 .value();
             });
           ctrl.are_we_go_for_duplication();
         };

         ctrl.dupliquer = function() {
           let devoirs = angular.copy(ctrl.cours.devoirs);
           ctrl.cours.$copie({
             regroupement_id: ctrl.creneaux_similaires.selected.regroupement_id,
             creneau_emploi_du_temps_id: ctrl.creneaux_similaires.selected.creneau_emploi_du_temps_id,
             date: ctrl.creneaux_similaires.selected.start
           }).then(function() {
             ctrl.actions_done.push(POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_DUPLICATED);
             toastr.success('', 'Séquence pédagogique copiée.');

             _(devoirs).each(function(devoir) {
               devoir.$copie({
                 cours_id: ctrl.cours.copie_id,
                 creneau_emploi_du_temps_id: devoir.creneau_cible.id,
                 date_due: devoir.creneau_cible.date_due
               })
                 .then(function() {
                   ctrl.actions_done.push(POPUP_ACTIONS.DEVOIR_DUPLICATED);
                   toastr.success('', 'Devoir copié.');
                   devoir.creneau_cible = [];
                 });
             });
             ctrl.creneaux_similaires = _(ctrl.creneaux_similaires).reject(function(creneau) {
               return creneau.id + creneau.start == ctrl.creneaux_similaires.selected.id + ctrl.creneaux_similaires.selected.start;
             });
             ctrl.creneaux_similaires.selected = [];
             init_cours_existant(ctrl.cours);

             swal({
               title: 'Créneau copié !',
               type: 'success',
               timer: 2000,
               showCancelButton: false,
               confirmButtonColor: '#ff6b55',
               confirmButtonText: 'Fermer'
             });
           });
         };
         // }}} /duplication

         ctrl.switch_to_modification_mode = function() {
           ctrl.mode_edition_creneau = false;
           ctrl.mode_duplication = false;
         };

         ctrl.switch_to_creneau_edition = function() {
           ctrl.dirty = true;
           ctrl.erreurs = [];
           ctrl.mode_edition_creneau = true;
         };
       }	// /fin gestion des Cours et Devoirs
       // }}}

       CurrentUser.get().then(function(response) {
         ctrl.current_user = response;

         if (!ctrl.current_user.parametrage_cahier_de_textes.affichage_week_ends) {
           delete ctrl.jours[0]; // sunday
           delete ctrl.jours[6]; // saturday
         }

         ctrl.creneau.mine = ctrl.creneau.en_creation || _.chain(ctrl.current_user.profil_actif.matieres).pluck('id').include(ctrl.creneau.matiere_id).value();
         ctrl.creneau.can_add_homework = ctrl.current_user.is(['ENS', 'DOC']) && _.chain(ctrl.current_user.profil_actif.matieres).pluck('id').include(ctrl.creneau.matiere_id).value();
         ctrl.creneau.etranger = !ctrl.current_user.is(['ADM']) && !ctrl.creneau.en_creation && !ctrl.creneau.mine;

         if (_(cours).isNull()) {
           if (!ctrl.creneau.etranger) {
             ctrl.cours = create_cours(creneau);
             ctrl.cours.editable = true;
           }
         } else {
           init_cours_existant(cours);
         }
        });
      }]);
