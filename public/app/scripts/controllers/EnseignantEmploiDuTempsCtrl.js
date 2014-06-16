'use strict';

angular.module('cahierDeTexteApp')
    .controller('EnseignantEmploiDuTempsCtrl',
		['$scope', '$modal', '$q', '$filter', 'CALENDAR_OPTIONS', 'CALENDAR_PARAMS', 'TINYMCE_OPTIONS', 'API', 'Annuaire', 'Documents', 'Cours', 'Devoirs', 'EmploisDuTemps', 'CreneauEmploiDuTemps', 'User',
		 function($scope, $modal, $q, $filter, CALENDAR_OPTIONS, CALENDAR_PARAMS, TINYMCE_OPTIONS, API, Annuaire, Documents, Cours, Devoirs, EmploisDuTemps, CreneauEmploiDuTemps, User) {
		     var types_de_devoir = API.query_types_de_devoir();
		     var matieres = [];
		     var matieres_enseignees = [];
		     $scope.classes = [];
		     $scope.classe = null;

		     var ouvre_popup_edition = function(raw_data,
							types_de_devoir, matieres, classes,
							creneau_selectionne, matiere_id, regroupement_id,
							cours, devoirs,
							popup_callback)
		     {
			 $modal.open({ templateUrl: 'app/views/enseignant/detail_emploi_du_temps.html',
				       controller: 'PopupEmploiDuTempsEditionCtrl',
				       resolve: {raw_data: function() {
					   return raw_data;
				       },
						 types_de_devoir: function() {
						     return types_de_devoir;
						 },
						 matieres: function() {
						     return matieres;
						 },
						 classes: function() {
						     return classes;
						 },
						 creneau_selectionne: function() {
						     return creneau_selectionne;
						 },
						 matiere_id: function() {
						     return matiere_id;
						 },
						 regroupement_id: function() {
						     return regroupement_id;
						 },
						 cours: function() {
						     return cours;
						 },
						 devoirs: function() {
						     return devoirs;
						 }
						}
				     }
				    ).result.then(// éxécuté à la fermeture de la popup
					function(scope_popup) {
					    // élimination des devoirs non finalisés
					    scope_popup.devoirs = _(scope_popup.devoirs).filter(function(devoir) {
						return _(devoir).has('id');
					    });

					    // appel du callback
					    popup_callback(scope_popup);
					});
		     };

		     // consommation des données //////////////////////////////
		     // helper
		     var update_fullCalendar_event = function(event, cours, devoirs) {
			 var clever_truncate = function(text, length) {
			     if (text.length > length) {
				 var result = text.substring(0, length);
				 result = result.substring(0, result.lastIndexOf(' '));
				 result += '…';
				 return result;
			     } else {
				 return text;
			     }
			 };

			 if (cours.deleted) {
			     return {details: {matiere_id: event.details.matiere_id,
					       regroupement_id: event.details.regroupement_id,
					       cahier_de_textes_id: event.details.cahier_de_textes_id,
					       creneau_emploi_du_temps_id: event.details.creneau_emploi_du_temps_id,
					       cours: {},
					       devoirs: []},
				     allDay: false,
				     title: '',
				     description: '',
				     regroupement: '',
				     start: event.start,
				     end: event.end,
				     className: 'clickable-event saisie-vide'};

			 } else {
			     var calendar_event = {details: {matiere_id: event.details.matiere_id,
							     regroupement_id: event.details.regroupement_id,
							     cahier_de_textes_id: event.details.cahier_de_textes_id,
							     creneau_emploi_du_temps_id: event.details.creneau_emploi_du_temps_id,
							     cours: cours,
							     devoirs: devoirs},
						   allDay: false,
						   title: '',
						   description: '',
						   regroupement: '',
						   start: event.start,
						   end: event.end,
						   className: 'clickable-event'};

			     // choix de la couleur
			     if (cours.contenu === undefined || cours.contenu.length == 0) {
				 calendar_event.className += ' saisie-vide';
			     } else {
				 if (devoirs.length > 0) {
				     calendar_event.className += ' saisie-devoirs';
				 } else {
				     if (cours.date_validation != null) {
					 calendar_event.className += ' saisie-valide';
				     } else {
					 calendar_event.className += ' saisie-invalide';
				     }
				 }
			     }

			     // composition de la description
			     if (_(cours).size() > 0) {
				 calendar_event.description += '<br><span style="color:' + CALENDAR_PARAMS.couleurs.cours + '">';
				 calendar_event.description += clever_truncate(cours.contenu, CALENDAR_PARAMS.cours_max_length);
				 calendar_event.description += '</span>';
			     }

			     if (event.details.regroupement_id !== undefined) {
				 calendar_event.regroupement = _.chain($scope.classes)
				     .filter(function(classe) {
					 return classe.id == event.details.regroupement_id;
				     })
				     .pluck('libelle')
				     .value()[0];
			     } else {
				 calendar_event.regroupement = '';
			     }

			     if (event.details.matiere_id.length > 0) {
				 if (matieres[ event.details.matiere_id ] === undefined) {
				     if (matieres_enseignees[ event.details.matiere_id ] === undefined) {
					 calendar_event.title = '{Matière inconnue}';
				     } else {
					 calendar_event.title = matieres_enseignees[ event.details.matiere_id ].libelle_long;
				     }
				 } else {
				     calendar_event.title = matieres[ event.details.matiere_id ].libelle_long;
				 }
			     }

			     return calendar_event;
			 }
		     };

		     var assemble_fullCalendar_event = function(item_emploi_du_temps) {
			 return update_fullCalendar_event({details: {matiere_id: item_emploi_du_temps.matiere_id,
								     regroupement_id: item_emploi_du_temps.regroupement_id,
								     cahier_de_textes_id: item_emploi_du_temps.cahier_de_textes_id,
								     creneau_emploi_du_temps_id: item_emploi_du_temps.creneau_emploi_du_temps_id},
							   start: item_emploi_du_temps.start,
							   end: item_emploi_du_temps.end},
							  item_emploi_du_temps.cours,
							  item_emploi_du_temps.devoirs);
		     };

		     var list_classes = function(user) {
			 return _.chain(user.classes)
			     .reject(function(classe) {
				 return classe.etablissement_code !== user.profil_actif.uai;
			     })
			     .pluck('regroupement_id')
			     .uniq()
			     .map(function(regroupement_id) {
				 return Annuaire.get_regroupement(regroupement_id);
			     })
			     .value();
		     };

		     var list_matieres_enseignees = function(user) {
			 return _.chain(user.classes)
			     .reject(function(classe) {
				 return classe.etablissement_code !== user.profil_actif.uai || classe.matiere_enseignee_id === undefined;
			     })
			     .pluck('matiere_enseignee_id')
			     .uniq()
			     .map(function(matiere_id) {
				 return [matiere_id, Annuaire.get_matiere(matiere_id)];
			     })
			     .object()
			     .value();
		     };


		     var list_matieres = function(raw_data) {
			 return _.chain(raw_data)
			     .pluck('matiere_id')
			     .uniq()
			     .map(function(matiere_id) {
				 return [matiere_id, Annuaire.get_matiere(matiere_id)];
			     })
			     .object()
			     .value();
		     };

		     var filter_data = function(raw_data) {
			 var filtered_data = raw_data;

			 // Filtrage sur une seule classe
			 if ($scope.classe != null) {
			     filtered_data = _($scope.raw_data).filter(function(creneau) {
				 return creneau.regroupement_id == $scope.classe;
			     });
			 }

			 return filtered_data;
		     };

		     var populate_calendar_events = function(data) {
			 $scope.calendar.events[0] = _(data).map(function(event) {
			     return assemble_fullCalendar_event(event);
			 });
		     };

		     var retrieve_data = function(from_date, to_date) {
			 User.get_user().then(function(response) {
			     $scope.current_user = response.data;

			     EmploisDuTemps.query(
				 {debut: from_date,
				  fin: to_date,
				  uai: $scope.current_user.profil_actif.uai},
				 function(response) {
				     $scope.raw_data = response;
				     // Extraction des matières
				     matieres = list_matieres($scope.raw_data);
				     matieres_enseignees = list_matieres_enseignees($scope.current_user);

				     // Extraction des classes
				     $scope.classes = list_classes($scope.current_user);

				     $q.all(matieres, $scope.classes).then(function(  ) {
					 // s'il y a des classes et des matières le calendrier est éditable (?)
					 $scope.calendar.options.editable = $scope.classes.length > 0 && _(matieres_enseignees).size() > 0;
					 $scope.calendar.options.selectable = $scope.calendar.options.editable;

					 $scope.refresh_calendar();
				     });
				 });
			 });
		     };

		     $scope.refresh_calendar = function() {
			 populate_calendar_events(filter_data($scope.raw_data));
		     };

		     var create_cours = function(creneau) {
			 var cours = new Cours({
			     cahier_de_textes_id: creneau.cahier_de_textes_id,
			     creneau_emploi_du_temps_id: creneau.id,
			     date_cours: new Date(creneau.start).toISOString()
			 });
			 cours.create = true;

			 return cours;
		     };

		     // configuration du composant calendrier /////////////////
		     $scope.calendar = {options: CALENDAR_OPTIONS,
					events: []};

		     $scope.calendar.options.eventRender = function(event, element) {
			 // FIXME: manipulation du DOM dans le contrôleur, sale, mais obligé pour l'interprétation du HTML ?
			 element.find('.fc-event-title').append(' - ' + event.regroupement + '<br>' + event.description);
		     };

		     $scope.calendar.options.viewRender = function(view, element) {
			 retrieve_data(view.visStart, new Date(view.visEnd - 1));
		     };

		     // édition d'un créneau existant
		     $scope.calendar.options.eventClick = function(event) {
			 var creneau_selectionne = _(event.source.events).findWhere({_id: event._id});
			 creneau_selectionne.id = creneau_selectionne.details.creneau_emploi_du_temps_id;
			 // 1. cours
			 var cours = null;
			 var devoirs = [];

			 if (creneau_selectionne.details.cours.id !== undefined) {
			     cours = API.get_cours({id: creneau_selectionne.details.cours.id});
			     cours.create = false;

			     $q.all(cours, types_de_devoir, matieres, $scope.classes)
				 .then(function() {
				     // 2. devoir
				     if (creneau_selectionne.details.devoirs.length > 0) {
					 _(creneau_selectionne.details.devoirs).each(function(devoir) {
					     devoirs.push(API.get_devoir({id: devoir.id}));
					 });
					 devoirs.create = false;
				     }
				 });
			 } else {
			     cours = create_cours(creneau_selectionne);
			 }

			 ouvre_popup_edition($scope.raw_data,
					     types_de_devoir, matieres_enseignees, $scope.classes,
					     creneau_selectionne, event.details.matiere_id, event.details.regroupement_id,
					     cours, devoirs,
					     function popup_callback(scope_popup) {
						 var index = _($scope.calendar.events[0]).indexOf(creneau_selectionne);
						 if (scope_popup.creneau_deleted) {
						     $scope.calendar.events[0].splice(index, 1);
						 } else {
						     var updated_event = update_fullCalendar_event(creneau_selectionne, scope_popup.cours, scope_popup.devoirs);
						     _.chain(updated_event)
							 .keys()
							 .reject(function(key) { //updated_event n'a pas de title
							     return key === "title" || key === "regroupement";
							 })
							 .each(function(propriete) {
							     $scope.calendar.events[0][ index ][ propriete ] = updated_event[ propriete ];
							 });

						     $scope.emploi_du_temps.fullCalendar('renderEvent', $scope.calendar.events[0][ index ]);
						 }
					     }
					    );
		     };

		     // création d'un nouveau créneau
		     // Le regroupement_id peut être null car on n'a pas fait de choix au niveau de la select box des classes sur full_calendar
		     $scope.calendar.options.select = function(start, end, allDay) {
			 start = $filter('correctTimezone')(start);
			 end = $filter('correctTimezone')(end);
			 var creneau_selectionne = new CreneauEmploiDuTemps({regroupement_id: $scope.classe === null ? '' : '' + $scope.classe,
									     jour_de_la_semaine: start.getDay() + 1,
									     heure_debut: new Date(new Date(start)).toISOString(),
									     heure_fin: new Date(new Date(end)).toISOString(),
									     matiere_id: ''
									    });
			 creneau_selectionne.$save()
			     .then(function() {
				 creneau_selectionne.dirty = true;
				 creneau_selectionne.start = start;
				 creneau_selectionne.heure_debut = start;
				 creneau_selectionne.heure_fin = end;

				 // durant le creneau_selectionne.$save() on perds regroupement_id
				 creneau_selectionne.regroupement_id = $scope.classe === null ? undefined : '' + $scope.classe;
				 creneau_selectionne.cahier_de_textes_id = $scope.classes[0].cahier_de_textes_id,
				 // 3. ouverture de la popup
				 $q.all(types_de_devoir, $scope.cours)
				     .then(function() {
					 creneau_selectionne.details = {cours: $scope.cours,
									devoirs: $scope.devoirs};
					 ouvre_popup_edition($scope.raw_data,
							     types_de_devoir, matieres_enseignees, $scope.classes,
							     creneau_selectionne, creneau_selectionne.matiere_id, creneau_selectionne.regroupement_id,
							     create_cours(creneau_selectionne), [],
							     function popup_callback(scope_popup) {
								 if (scope_popup.dirty) {
								     creneau_selectionne.matiere_id = scope_popup.matiere_id;
								     creneau_selectionne.regroupement_id = scope_popup.regroupement_id;
								     creneau_selectionne.cahier_de_textes_id = scope_popup.cours.cahier_de_textes_id;
								     creneau_selectionne.$update();
								     $scope.calendar.events[0].push(assemble_fullCalendar_event({cours: scope_popup.cours,
																 devoirs: scope_popup.devoirs,
																 cahier_de_textes_id: scope_popup.cours.cahier_de_textes_id,
																 creneau_emploi_du_temps_id: scope_popup.cours.creneau_emploi_du_temps_id,
																 matiere_id: scope_popup.matiere_id,
																 regroupement_id: scope_popup.regroupement_id,
																 start: creneau_selectionne.heure_debut,
																 end: creneau_selectionne.heure_fin}));

								     $scope.emploi_du_temps.fullCalendar('renderEvent', _($scope.calendar.events[0]).last(), true);
								 } else {
								     creneau_selectionne.$delete(); //full stop
								 }
							     }
							    );
				     });

				 $scope.emploi_du_temps.fullCalendar('unselect');
			     });
		     };
		 }]);
