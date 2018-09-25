'use strict';

angular.module('cahierDeTextesClientApp')
  .controller('TextBookCtrl',
    ['$scope', 'moment', '$state', '$q', '$locale',
      'APP_PATH', 'SEMAINES_VACANCES', 'ZONE', 'PopupsCreneau', 'CreneauxEmploiDuTemps', 'Utils', 'Annuaire', 'CurrentUser', 'API',
      'current_user',
      function($scope, moment, $state, $q, $locale,
        APP_PATH, SEMAINES_VACANCES, ZONE, PopupsCreneau, CreneauxEmploiDuTemps, Utils, Annuaire, CurrentUser, API,
               current_user) {
        let ctrl = $scope;
        ctrl.$ctrl = $scope;

        ctrl.current_user = current_user;
        ctrl.uniquement_mes_creneaux = !ctrl.current_user.is(['EVS', 'DIR', 'ADM']);
        let can_edit = ctrl.current_user.is(['ENS', 'DOC', 'DIR', 'ADM']);

        ctrl.emploi_du_temps = angular.element('#emploi_du_temps');
        let popup_ouverte = false;
        let first_load = true;

        let set_preferred_view = function(view) {
          ctrl.current_user.parametrage_cahier_de_textes.preferredView = view;
          CurrentUser.update_parameters(ctrl.current_user.parametrage_cahier_de_textes);
        };

        if (!_(ctrl.current_user.parametrage_cahier_de_textes).has('preferredView')) {
          set_preferred_view('timetableWeek');
        }

        ctrl.filter_data = function(raw_data) {
          if (ctrl.current_user.is(['EVS', 'DIR', 'ADM'])) {
            return filter_by_regroupement(raw_data, ctrl.selected_regroupements);
          } else if (ctrl.current_user.is(['ENS', 'DOC'])) {
            return filter_by_matieres(filter_by_regroupement(raw_data,
              ctrl.selected_regroupements),
              ctrl.current_user.extract_subjects_ids(),
              ctrl.uniquement_mes_creneaux);
          } else {
            return raw_data;
          }
        };

        ctrl.prev = function() { ctrl.emploi_du_temps.fullCalendar('prev'); };
        ctrl.next = function() { ctrl.emploi_du_temps.fullCalendar('next'); };

        ctrl.select_all_regroupements = function() {
          ctrl.selected_regroupements = ctrl.groups;
          ctrl.refresh_calendar();
        };

        ctrl.select_no_regroupements = function() {
          ctrl.selected_regroupements = [];
          ctrl.refresh_calendar();
        };

        let popup_callback = function(scope_popup) {
          let view = ctrl.emploi_du_temps.fullCalendar('getView');
          retrieve_data(view.start.toDate(), view.end.toDate());
        };

        // configuration du composant calendrier

          if (ctrl.current_user.is(['EVS', 'DIR', 'ADM'])) {
              Annuaire.get_groups_of_structures(current_user.get_structures_ids())
                  .then(function(groups) {
                      ctrl.groups = groups.data;
                      if (ctrl.current_user.is(['ENS'])) {
                          ctrl.current_user.get_actual_groups()
                              .then(function(actual_groups) {
                                  ctrl.selected_regroupements = ctrl.groups;
                              });

                      } else {
                          ctrl.selected_regroupements = [ ctrl.groups[0] ];
                      }
                  });
          } else {
              ctrl.current_user.get_actual_groups()
                  .then(function(actual_groups) {
                      ctrl.groups = actual_groups;
                      ctrl.selected_regroupements = ctrl.groups;
                  });
          }

        ctrl.extraEventSignature = (event) => `${event.matiere}`;

        let filter_by_regroupement = function(raw_data, selected_regroupements) {
          return _(raw_data).filter(function(creneau) {
            return _.chain(selected_regroupements).pluck('id').contains(parseInt(creneau.regroupement_id)).value();
          });
        };
        let filter_by_matieres = function(raw_data, subjects_ids, active) {
          return !active ? raw_data : _(raw_data).filter(function(creneau) {
            return _(subjects_ids).contains(creneau.matiere_id) || creneau.matiere_id == '';
          });
        };

        ctrl.calendar = {
          options: {
            lang: 'fr',
            locale: 'fr',
            height: 600,
            header: {
              left: ctrl.current_user.is(['ENS', 'DOC']) ? 'timetableWeek,textbookWeek' : '',
              center: 'title',
              right: 'today prev,next'
            },
            firstDay: 1,
            minTime: '07:00:00',
            maxTime: '19:00:00',
            businessHours: {
              start: '7:00',
              end: '19:00',
              dow: [1, 2, 3, 4, 5]
            },
            titleFormat: 'D MMM YYYY, [semaine] W',
            columnFormat: 'dddd D',
            slotDuration: '00:30:00',
            slotEventOverlap: false,
            ignoreTimezone: false,
            slotLabelFormat: $locale.DATETIME_FORMATS.shortTime,
            allDaySlot: false,
            theme: false,
            defaultView: ctrl.current_user.parametrage_cahier_de_textes.preferredView,
            editable: can_edit,
            eventDurationEditable: can_edit,
            eventStartEditable: can_edit,
            selectable: can_edit,
            selectHelper: true,
            weekends: ctrl.current_user.parametrage_cahier_de_textes.affichage_week_ends,
            // view specific options [https://fullcalendar.io/docs/views/View-Specific-Options/]
            views: {
              timetableWeek: {
                type: 'agenda',
                duration: { weeks: 1 },
                buttonText: 'Emploi du temps',
                displayEventTime: false
              },
              textbookWeek: {
                type: 'list',
                duration: { weeks: 1 },
                buttonText: 'Liste'
              }
            },

            viewRender: function(view, element) {
              ctrl.current_user.date = view.start;
              ctrl.c_est_les_vacances = Utils.sont_ce_les_vacances(view.start.week(), ZONE);

              if (view.name != ctrl.current_user.parametrage_cahier_de_textes.preferredView) {
                set_preferred_view(view.name);
              }

              retrieve_data(view.start.toDate(), view.end.toDate());
            },

            eventRender: function(event, element, view) {
              let elt_fc_content = element.find('.fc-content');

              if (!ctrl.current_user.is(['ELV', 'TUT'])) {
                if (event.temps_estime > 0) {
                  let class_couleur = '';
                  if (event.temps_estime < 4) {
                    class_couleur = ' label-success';
                  } else if (event.temps_estime < 8) {
                    class_couleur = ' label-info';
                  } else if (event.temps_estime < 12) {
                    class_couleur = ' label-warning';
                  } else if (event.temps_estime <= 15) {
                    class_couleur = ' label-danger';
                  }
                  elt_fc_content.prepend(`<div class="est-time est-time-${event.temps_estime} ${class_couleur}"></div>`);
                }
              }

              if (event.has_resources) {
                elt_fc_content.prepend('<i class="glyphicon glyphicon-paperclip"></i>');
              }

              let elt_fc_content_title = element.find('.fc-list-item-title');
              if (elt_fc_content_title.length > 0
                && (!_(event.details.cours).isNull() || !_(event.details.devoirs).isEmpty())) {
                let event_content = `${elt_fc_content_title.html()}<br><div class="col-md-6 sequence-pedagogique">`;

                if (!_(event.details.cours).isNull()) {
                  event_content += `
              <fieldset>
                <legend>Séquence pédagogique</legend>
                ${event.details.cours.contenu}
              </fieldset>`;
                }
                event_content += '</div>';

                if (!_(event.details.devoirs).isEmpty()) {
                  event_content += `<fieldset>
< legend > Devoirs < /legend>`;
                  event_content += '<ul class="col-md-6 devoirs">';
                  _(event.details.devoirs).each(function(assignement) {
                    let additional_classes = ctrl.current_user.is(['ELV']) ? (assignement.fait ? 'fait' : 'a-faire') : '';

                    event_content += `  <li class="devoir type${assignement.type_devoir_id} ${additional_classes}">`;
                    if (ctrl.current_user.parametrage_cahier_de_textes.affichage_types_de_devoir) {
                      event_content += `    <span class="type">${assignement.type_devoir_description}</span>`;
                    }

                    if (assignement.temps_estime > 0) {
                      event_content += `    <span class="temps-estime">${assignement.temps_estime * 5} minutes</span>
${assignement.contenu}
                      </li>`;
                    }
                  });
                  event_content += `</ul>
</fieldset>`;
                }

                elt_fc_content_title.html(event_content);
              }
            },

            eventClick: function(event) {
              if (ctrl.current_user.is(['ENS', 'DOC', 'ADM'])) {
                if (!popup_ouverte) {
                  CreneauxEmploiDuTemps.get({ id: event.details.creneau_emploi_du_temps_id })
                    .$promise
                    .then(function(creneau_selectionne) {
                      creneau_selectionne.dirty = false;
                      creneau_selectionne.en_creation = false;
                      creneau_selectionne.heure_debut = event.start;
                      creneau_selectionne.heure_fin = event.end;
                      creneau_selectionne.regroupement_id = event.details.regroupement_id;

                      ctrl.current_user.get_actual_subjects()
                        .then(function(actual_subjects) {
                          PopupsCreneau.edition(ctrl.raw_data,
                                                actual_subjects,
                                                ctrl.current_user.actual_groups,
                                                creneau_selectionne,
                                                event.details.cours,
                                                event.details.devoirs,
                                                popup_callback,
                                                popup_ouverte);
                        });
                    });
                }
              } else {
                if (!popup_ouverte && ((event.details.devoirs.length > 0) || (!_(event.details.cours).isNull() && _(event.details.cours).has('contenu')))) {
                  PopupsCreneau.display(event.matiere,
                    event.details.cours,
                    event.details.devoirs,
                    popup_callback,
                    popup_ouverte);
                }
              }
            },

            select: function(start, end, allDay) {
              if (ctrl.calendar.options.selectable && ctrl.calendar.options.editable && ctrl.selected_regroupements.length > 0) {
                if (end - start == 1800000) {
                  end = moment(end).add(30, 'minutes').toDate();
                }
                if (!popup_ouverte) {
                  // création du créneau avec les bons horaires
                  start = new Date(start);
                  end = new Date(end);
                  let regroupement_id = ctrl.selected_regroupements[0].id;
                  let new_creneau = new CreneauxEmploiDuTemps({
                    regroupement_id: regroupement_id,
                    jour_de_la_semaine: start.getDay(),
                    heure_debut: moment(start).toISOString(),
                    heure_fin: moment(end).toISOString(),
                    matiere_id: ''
                  });

                  new_creneau.$save()
                    .then(function() {
                      new_creneau.dirty = true;
                      new_creneau.en_creation = true;
                      new_creneau.heure_debut = start;
                      new_creneau.heure_fin = end;
                      new_creneau.regroupement_id = regroupement_id;


                      ctrl.current_user.get_actual_subjects()
                        .then(function(actual_subjects) {
                          PopupsCreneau.edition(ctrl.raw_data,
                                                actual_subjects, ctrl.current_user.actual_groups,
                                                new_creneau, null, [],
                            popup_callback, popup_ouverte);
                        });

                      ctrl.emploi_du_temps.fullCalendar('unselect');
                    });
                }
              }
            },

            eventDrop: function(event, delta, revertFunc, jsEvent, ui, view) {
              if (ctrl.calendar.options.selectable && ctrl.calendar.options.editable) {
                CreneauxEmploiDuTemps.update({
                  id: event.details.creneau_emploi_du_temps_id,
                  heure_debut: event.start.toDate(),
                  heure_fin: event.end.toDate(),
                  jour_de_la_semaine: event.end.day()
                });
              }
            },

            eventResize: function(event, delta, revertFunc, jsEvent, ui, view) {
              if (ctrl.calendar.options.selectable && ctrl.calendar.options.editable) {
                CreneauxEmploiDuTemps.update({
                  id: event.details.creneau_emploi_du_temps_id,
                  heure_debut: event.start.toDate(),
                  heure_fin: event.end.toDate()
                });
              }
            }
          },
          events: []
        };

        // consommation des données
        let CalendarEvent = function(event) {
          let fc_event = this; //pour pouvoir le référencé dans les .then()
          fc_event.details = event;
          fc_event.allDay = false;
          fc_event.regroupement = _(ctrl.current_period_groups).findWhere({ id: parseInt(fc_event.details.regroupement_id) });
          fc_event.title = (_(fc_event.regroupement).isUndefined()) ? '' : fc_event.regroupement.name;
          fc_event.matiere = _(ctrl.subjects).findWhere({ id: fc_event.details.matiere_id });
          fc_event.has_resources = _(event.cours).has('ressources') && event.cours.ressources.length > 0;
          fc_event.temps_estime = 0;
          fc_event.start = moment(event.start);
          fc_event.end = moment(event.end);
          fc_event.className = 'saisie-vide';

          if (!_(fc_event.matiere).isUndefined()) {
            fc_event.title += ' - ' + fc_event.matiere.name;
          }

          if (!_(event.cours).isNull()) {
            _(event.cours.devoirs).each(function(devoir) {
              fc_event.has_ressources = fc_event.has_ressources || _(devoir).has('ressources') && devoir.ressources.length > 0;
            });
          }

          _(event.devoirs).each(function(devoir) {
            fc_event.has_ressources = fc_event.has_ressources || _(devoir).has('ressources') && devoir.ressources.length > 0;
            if (!_(devoir.temps_estime).isNull()) {
              fc_event.temps_estime += devoir.temps_estime;
              if (fc_event.temps_estime > 15) {
                fc_event.temps_estime = 15;
              }
            }
          });

          // couleur de la case
          if (event.devoirs.length > 0) {
            let highest_type_de_devoir = _.chain(event.devoirs).pluck('type_devoir_id').sort().first().value();
            switch (highest_type_de_devoir) {
              case 1:
                fc_event.className = 'edt-devoir-note-surveille';
                break;
              case 2:
                fc_event.className = 'edt-devoir-note-maison';
                break;
              default:
                if (ctrl.current_user.is(['ELV'])) {
                  fc_event.className = _.chain(event.devoirs).pluck('fait').contains(true).value() ? 'edt-devoir-fait' : 'edt-devoir-a-faire';
                }
            }
          } else {
            fc_event.className = 'edt-cours';
            if (!_(event.cours).isNull() && !_(event.cours.date_validation).isNull() && ctrl.current_user.is(['ENS', 'DOC'])) {
              fc_event.className += '-valide';
            } else if (!_(event.cours).isNull()) {
              fc_event.className += '-saisie';
            }
          }

          if (ctrl.current_user.is(['ELV', 'TUT', 'EVS', 'DIR', 'ADM']) && _(event.cours).isNull() && _(event.devoirs).isEmpty()) {
            fc_event.className += ' unclickable-event';
          } else {
            fc_event.className += ' clickable-event';
          }
        };

        ctrl.refresh_calendar = function() {
          ctrl.calendar.events[0] = _(ctrl.filter_data(ctrl.raw_data)).map(function(event) { return new CalendarEvent(event); });
        };

        let retrieve_data = function(from_date, to_date) {
          API.get_emploi_du_temps(
            from_date,
            to_date,
            ctrl.current_user.enfant_actif == undefined ? null : ctrl.current_user.enfant_actif.child_id
          )
            .then(function success(response) {
              ctrl.raw_data = response.data;
              let groups_ids = _.chain(ctrl.raw_data).pluck('regroupement_id').uniq().value();
              let subjects_ids = _.chain(ctrl.raw_data).pluck('matiere_id').uniq().value();
              let promise = _(groups_ids).isEmpty() ? $q.resolve([]) : Annuaire.get_groups(groups_ids);

              promise
                .then(function(response) {
                  ctrl.current_period_groups = response.data;

                  return Annuaire.get_subjects(subjects_ids);
                })
                .then(function(response) {
                  ctrl.subjects = response.data;

                  ctrl.refresh_calendar();
                });
            });
        };
      }]);
