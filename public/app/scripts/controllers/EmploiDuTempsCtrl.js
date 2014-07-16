'use strict';

angular.module('cahierDeTexteApp')
    .controller('EmploiDuTempsCtrl',
		[ '$scope', '$modal', '$q', '$filter', 'CALENDAR_OPTIONS', 'CALENDAR_PARAMS', 'API', 'Annuaire', 'EmploisDuTemps', 'User', 'CreneauEmploiDuTemps',
		  function ( $scope, $modal, $q, $filter, CALENDAR_OPTIONS, CALENDAR_PARAMS, API, Annuaire, EmploisDuTemps, User, CreneauEmploiDuTemps ) {
		      var filter_data = angular.identity;
		      var matieres = [];
		      var matieres_enseignees = [];

		      $scope.creneau_selectionne = {};

		      // popup d'affichage des détails
		      var ouvre_popup_details = function( titre, cours, devoirs ) {
			  $modal.open( { templateUrl: 'app/views/eleve/detail_emploi_du_temps.html',
					 controller: 'EmploiDuTempsPopupDisplayCtrl',
					 resolve: { titre  : function() { return titre; },
						    cours  : function() { return cours; },
						    devoirs: function() { return devoirs; } } }
				     ).result.then( function ( scope_popup ) {
					 _(scope_popup.devoirs).each(function(devoir) {
					     _($scope.calendar.events[0]).findWhere({type: 'devoir', id: devoir.id}).className = devoir.fait ? ' saisie-devoirs-fait' : ' saisie-devoirs';
					 });
					 $scope.emploi_du_temps.fullCalendar( 'renderEvent', $scope.creneau_selectionne );
				     });
		      };
		      // popup d'édition
		      var ouvre_popup_edition = function ( raw_data, matieres, classes, creneau_selectionne, cours, devoirs, popup_callback ) {
			  $modal.open( {
			      templateUrl: 'app/views/enseignant/edition_emploi_du_temps.html',
			      controller: 'EmploiDuTempsPopupEditionCtrl',
			      resolve: {
				  raw_data	     : function () { return raw_data; },
				  matieres	     : function () { return matieres; },
				  classes	     : function () { return classes; },
				  creneau_selectionne: function () { return creneau_selectionne; },
				  cours		     : function () { return cours; },
				  devoirs	     : function () { return devoirs; }
			      }
			  } )
			      .result.then( // éxécuté à la fermeture de la popup
				  function ( scope_popup ) {
				      // élimination des devoirs non finalisés
				      scope_popup.devoirs = _( scope_popup.devoirs )
					  .filter( function ( devoir ) {
					      return _( devoir )
						  .has( 'id' );
					  } );

				      // appel du callback
				      popup_callback( scope_popup );
				  } );
		      };

		      // consommation des données
		      var CalendarEvent = function( event, item ) {
			  var _this = this; //pour pouvoir le référencé dans les .then()
			  this.details = event;
			  this.allDay = false;
			  this.title = '';
			  this.regroupement = _($scope.classes).findWhere({ id: parseInt( this.details.regroupement_id ) });
			  this.type = ( _(item).has( 'fait' ) ) ? 'devoir': 'cours';
			  this.has_resources = _(item).has( 'ressources' ) && item.ressources.length > 0;

			  if ( this.type === 'cours' ) {
			      item.start = event.start;
			      item.end = event.end;
			      this.className = item.date_validation === null ? 'saisie-invalide' : 'saisie-valide';
			      if ( event.matiere_id.length > 0 ) {
				  Annuaire.get_matiere( event.matiere_id ).$promise.then( function success( response ) {
				      _this.title += response.libelle_long;
				  });
			      }
			  } else {
			      this.className = item.fait ? 'saisie-devoirs-fait' : 'saisie-devoirs';

			      API.get_type_de_devoir( { id: item.type_devoir_id } )
				  .$promise.then( function success( response ) {
				      _this.title += response.label;
				  });
			  }
			  this.start = new Date( item.start );
			  this.end = new Date( item.end );

			  if ( _(item).has( 'contenu' ) && item.contenu.length > 0 ) {
			      this.id = item.id;
			  } else {
			      this.className = 'saisie-vide';
			  }

			  if ( ( $scope.current_user.profil_actif.type === 'ELV' && _(item).has( 'contenu' ) && item.contenu.length > 0 ) ||
			       ( $scope.current_user.profil_actif.type === 'ENS' && this.details.enseignant_id === $scope.current_user.uid ) ) {
			      this.className += ' clickable-event';
			  } else {
			      this.className += ' unclickable-event';
			  }

		      };

		      var fullCalendarize_event = function( item_emploi_du_temps ) {
			  var events = [];

			  // traitement du cours
			  events.push( new CalendarEvent( item_emploi_du_temps, item_emploi_du_temps.cours ) );

			  // traitement des devoirs
			  _(item_emploi_du_temps.devoirs).each( function( devoir ) {
			      events.push( new CalendarEvent( item_emploi_du_temps, devoir ) );
			  });

			  return events;
		      };

		      var populate_calendar = function( raw_data ) {
			  var events = _.chain( raw_data )
				  .map( function( event ) {
				      return fullCalendarize_event( event );
				  } )
				  .flatten()
				  .value();
			  $scope.calendar.events[0] = _(events).filter( function( event ) { return event.type === 'cours'; } );
			  $scope.calendar.events[1] = _(events).filter( function( event ) { return event.type === 'devoir'; } );
		      };

		      var retrieve_data = function( from_date, to_date ) {
			  EmploisDuTemps.query( { debut: from_date,
						  fin: to_date,
						  uai: $scope.current_user.profil_actif.uai } )
			      .$promise
			      .then( function success( response ) {
				  $scope.raw_data = response;
				  $scope.refresh_calendar();
			      });
		      };

		      $scope.refresh_calendar = function(  ) {
			  populate_calendar( filter_data( $scope.raw_data ) );
		      };

		      // configuration du composant calendrier
		      $scope.calendar = { options: CALENDAR_OPTIONS,
					  events: [  ] };

		      $scope.calendar.options.viewRender = function( view, element ) {
			  // population des créneaux d'emploi du temps avec les cours et devoirs éventuels
			  retrieve_data( view.visStart, view.visEnd );
		      };

		      User.get_user().then( function( response ) {
			  $scope.current_user = response.data;

			  switch ( $scope.current_user.profil_actif.type ) {
			  case 'ENS':
			      $scope.uniquement_mes_creneaux = true;
			      $scope.calendar.options.selectable = true;
			      $scope.calendar.options.editable = true;

			      var list_classes = function(user) {
				  return _.chain( user.profil_actif.classes )
				      .reject(function(classe) {
					  return classe.etablissement_code !== user.profil_actif.uai;
				      })
				      .pluck('regroupement_id')
				      .uniq()
				      .compact()
				      .reject( function( id ) { return id === 'undefined'; } )
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
				      .compact()
				      .reject( function( id ) { return id === 'undefined'; } )
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
				      .compact()
				      .reject( function( id ) { return id === 'undefined'; } )
				      .map(function(matiere_id) {
					  return [matiere_id, Annuaire.get_matiere(matiere_id)];
				      })
				      .object()
				      .value();
			      };

			      matieres = list_matieres( $scope.current_user );
			      matieres_enseignees = list_matieres_enseignees( $scope.current_user );
			      $scope.classes = list_classes( $scope.current_user );

			      var popup_callback = function( scope_popup ) {
				  var view = $scope.emploi_du_temps.fullCalendar( 'getView' );
				  retrieve_data( view.visStart, view.visEnd );
			      };

			      // édition d'un créneau existant
			      $scope.calendar.options.eventClick = function ( event ) {
				  CreneauEmploiDuTemps.get( { id: event.details.creneau_emploi_du_temps_id } )
				      .$promise
				      .then( function( response ) {
					  var creneau_selectionne = response;
					  creneau_selectionne.dirty = false;
					  creneau_selectionne.heure_debut = event.start;
					  creneau_selectionne.heure_fin = event.end;
					  creneau_selectionne.regroupement_id = event.details.regroupement_id;
					  creneau_selectionne.cahier_de_textes_id = event.details.cahier_de_textes_id;

					  // 1. cours
					  var cours = null;
					  var devoirs = [];

					  if ( event.details.cours.id !== undefined ) {
					      cours = API.get_cours( { id: event.details.cours.id } );
					      cours.create = false;

					      $q.all( cours, matieres, $scope.classes )
						  .then( function () {
						      // 2. devoir
						      if ( event.details.devoirs.length > 0 ) {
							  _( event.details.devoirs )
							      .each( function ( devoir ) {
								  API.get_devoir( { id: devoir.id } )
								      .$promise
								      .then( function ( vrai_devoir ) {
									  devoirs.push( vrai_devoir );
								      } );
							      } );
							  devoirs.create = false;
						      }
						  } );
					  }

					  ouvre_popup_edition( $scope.raw_data,
							       matieres_enseignees, $scope.classes,
							       creneau_selectionne, cours, devoirs,
							       popup_callback );
				      } );
			      };

			      // création d'un nouveau créneau
			      // Le regroupement_id peut être null car on n'a pas fait de choix au niveau de la select box des classes sur full_calendar
			      $scope.calendar.options.select = function ( start, end, allDay ) {
				  // création du créneau avec les bons horaires
				  start = $filter('correctTimeZone')(start);
				  end = $filter('correctTimeZone')(end);
				  var new_creneau = new CreneauEmploiDuTemps( { regroupement_id: $scope.classe === null ? '' : '' + $scope.classe,
										jour_de_la_semaine: start.getDay() + 1,
										heure_debut: new Date(new Date(start)).toISOString(),
										heure_fin: new Date(new Date(end)).toISOString(),
										matiere_id: '' } );

				  new_creneau.$save()
				      .then( function () {
					  new_creneau.dirty = true;
					  new_creneau.heure_debut = start;
					  new_creneau.heure_fin = end;
					  new_creneau.regroupement_id = $scope.classe === null ? undefined : '' + $scope.classe;
					  new_creneau.cahier_de_textes_id = $scope.classes[ 0 ].cahier_de_textes_id;

					  ouvre_popup_edition( $scope.raw_data,
							       matieres_enseignees, $scope.classes,
							       new_creneau, null, [],
							       popup_callback );

					  $scope.emploi_du_temps.fullCalendar( 'unselect' );
				      } );
			      };

			      $scope.calendar.options.eventRender = function ( event, element ) {
				  // FIXME: manipulation du DOM dans le contrôleur, sale, mais obligé pour l'interprétation du HTML ?
				  var html_element = element.find( '.fc-event-title' );

				  var regroupement = event.regroupement !== 'undefined' ? event.regroupement.libelle : '';
				  html_element.append( ' - ' + regroupement );
				  if ( event.has_resources ) {
				      html_element.prepend( '<i class="glyphicon glyphicon-paperclip"></i>' );
				  }
			      };

			      filter_data = function( raw_data ) {
				  var filtered_data = raw_data;

				  // Filtrage sur une seule classe
				  if ( $scope.classe != null ) {
				      filtered_data = _( filtered_data ).filter( function( creneau ) {
					  return creneau.regroupement_id == $scope.classe;
				      } );
				  }

				  if ( $scope.uniquement_mes_creneaux ) {
				      filtered_data = _( filtered_data ).filter( function( creneau ) {
					  return creneau.enseignant_id === $scope.current_user.uid;
				      } );
				  }

				  return filtered_data;
			      };
			      break;

			  case 'ELV':
			  default:
			      $scope.calendar.options.eventRender = function( event, element ) {
				  var html_element = element.find( '.fc-event-title' );

				  if ( event.has_resources ) {
				      html_element.prepend( '<i class="glyphicon glyphicon-paperclip"></i>' );
				  }

			      };
			      $scope.calendar.options.eventClick = function( event ) {
				  if ( _(event.details.cours).has( 'contenu' ) ) {
				      $scope.creneau_selectionne = event;
				      ouvre_popup_details( event.title, event.details.cours, event.details.devoirs );
				  }
			      };
			      break;
			  }

		      } );
		  } ] );
