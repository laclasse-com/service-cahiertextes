'use strict';

angular.module('cahierDeTexteApp')
    .controller('EmploiDuTempsCtrl',
		[ '$scope', '$modal', '$q', '$filter', 'CALENDAR_OPTIONS', 'CALENDAR_PARAMS', 'API', 'Annuaire', 'EmploisDuTemps', 'User', 'CreneauEmploiDuTemps',
		  function ( $scope, $modal, $q, $filter, CALENDAR_OPTIONS, CALENDAR_PARAMS, API, Annuaire, EmploisDuTemps, User, CreneauEmploiDuTemps ) {
		      var filter_data = angular.identity;
		      var types_de_devoir = [];
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
		      var ouvre_popup_edition = function ( raw_data, types_de_devoir, matieres, classes, creneau_selectionne, matiere_id, regroupement_id, cours, devoirs, popup_callback ) {
			  $modal.open( {
			      templateUrl: 'app/views/enseignant/edition_emploi_du_temps.html',
			      controller: 'EmploiDuTempsPopupEditionCtrl',
			      resolve: {
				  raw_data	     : function () { return raw_data; },
				  types_de_devoir    : function () { return types_de_devoir; },
				  matieres	     : function () { return matieres; },
				  classes	     : function () { return classes; },
				  creneau_selectionne: function () { return creneau_selectionne; },
				  matiere_id	     : function () { return matiere_id; },
				  regroupement_id    : function () { return regroupement_id; },
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
			  this.details = { cours: event.cours,
					   devoirs: event.devoirs,
					   cahier_de_textes_id: event.cahier_de_textes_id,
					   regroupement_id: event.regroupement_id,
					   matiere_id: event.matiere_id,
					   creneau_emploi_du_temps_id: event.creneau_emploi_du_temps_id };
			  this.allDay = false;
			  this.title = '';
			  this.description = '';
			  this.regroupement = _($scope.classes).findWhere({ id: parseInt( this.details.regroupement_id ) });
			  this.type = ( _(item).has( 'fait' ) ) ? 'devoir': 'cours';

			  if ( this.type === 'cours' ) {
			      item.start = event.start;
			      item.end = event.end;
			      this.className = 'saisie-invalide';
			      if ( event.matiere_id.length > 0 ) {
				  Annuaire.get_matiere( event.matiere_id ).$promise.then( function success( response ) {
				      _this.title = response.libelle_long;
				  });
			      }
			  } else {
			      this.className = item.fait ? 'saisie-devoirs-fait' : 'saisie-devoirs';

			      API.get_type_de_devoir( { id: item.type_devoir_id } )
				  .$promise.then( function success( response ) {
				      _this.title = response.label;
				  });
			  }
			  this.className += ' clickable-event';
			  this.start = new Date( item.start );
			  this.end = new Date( item.end );

			  if ( _(item).has( 'contenu' ) && item.contenu.length > 0 ) {
			      this.description += '<br><span style="color:' + CALENDAR_PARAMS.couleurs[ this.type ] + '">';
			      this.description += item.contenu.substring( 0, CALENDAR_PARAMS.max_length );
			      this.description += item.contenu.length > CALENDAR_PARAMS.max_length ? '…' : '';
			      this.description += '</span>';
			      this.className += ' clickable-event';
			      this.id = item.id;
			  } else {
			      this.className = 'saisie-vide un-clickable-event';
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

		      // configuration du composant calendrier
		      $scope.calendar = { options: CALENDAR_OPTIONS,
					  events: [  ] };

		      User.get_user().then( function( response ) {
			  $scope.current_user = response.data;

			  var populate_calendar = function( raw_data ) {
			      $scope.calendar.events[0] = _.chain( raw_data )
				  .map( function( event ) {
				      return fullCalendarize_event( event );
				  } )
				  .flatten()
				  .value();
			  };

			  $scope.refresh_calendar = function(  ) {
			      populate_calendar( filter_data( $scope.raw_data ) );
			  };

			  var retrieve_data = function( from_date, to_date ) {
			      EmploisDuTemps.query(
				  { debut: from_date,
				    fin: to_date,
				    uai: $scope.current_user.profil_actif.uai },
				  function( response ) {
				      $scope.raw_data = response;
				      $scope.refresh_calendar();
				  });
			  };

			  $scope.calendar.options.viewRender = function( view, element ) {
			      // population des créneaux d'emploi du temps avec les cours et devoirs éventuels
			      retrieve_data( view.visStart, view.visEnd );
			  };

			  switch ( $scope.current_user.profil_actif.type ) {
			  case 'ENS':
			      $scope.uniquement_mes_creneaux = false;
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

			      types_de_devoir = API.query_types_de_devoir();
			      matieres = list_matieres( $scope.current_user );
			      matieres_enseignees = list_matieres_enseignees( $scope.current_user );
			      $scope.classes = list_classes( $scope.current_user );

			      var popup_callback = function( scope_popup ) {
				  var view = $scope.emploi_du_temps.fullCalendar( 'getView' );
				  retrieve_data( view.visStart, view.visEnd );
			      };

			      // édition d'un créneau existant
			      $scope.calendar.options.eventClick = function ( event ) {
				  var creneau_selectionne = _( event.source.events )
					  .findWhere( {
					      _id: event._id
					  } );
				  creneau_selectionne.id = creneau_selectionne.details.creneau_emploi_du_temps_id;

				  // 1. cours
				  var cours = null;
				  var devoirs = [];

				  if ( creneau_selectionne.details.cours.id !== undefined ) {
				      cours = API.get_cours( {
					  id: creneau_selectionne.details.cours.id
				      } );
				      cours.create = false;

				      $q.all( $scope.cours, types_de_devoir, matieres, $scope.classes )
					  .then( function () {
					      // 2. devoir
					      if ( creneau_selectionne.details.devoirs.length > 0 ) {
						  _( creneau_selectionne.details.devoirs )
						      .each( function ( devoir ) {
							  API.get_devoir( {
							      id: creneau_selectionne.details.devoirs[ 0 ].id
							  } )
							      .$promise
							      .then( function ( vrai_devoir ) {
								  devoirs.push( vrai_devoir );
							      } );
						      } );
						  devoirs.create = false;
					      }
					  } );
				  } else {
				      cours = null;
				  }
				  ouvre_popup_edition( $scope.raw_data,
						       types_de_devoir, matieres_enseignees, $scope.classes,
						       creneau_selectionne, event.details.matiere_id, event.details.regroupement_id,
						       cours, devoirs,
						       popup_callback );
			      };

			      // création d'un nouveau créneau
			      // Le regroupement_id peut être null car on n'a pas fait de choix au niveau de la select box des classes sur full_calendar
			      $scope.calendar.options.select = function ( start, end, allDay ) {
				  start = $filter('correctTimeZone')(start);
				  end = $filter('correctTimeZone')(end);
				  var creneau_selectionne = new CreneauEmploiDuTemps({
				      regroupement_id: $scope.classe === null ? '' : '' + $scope.classe,
				      jour_de_la_semaine: start.getDay() + 1,
				      heure_debut: new Date(new Date(start)).toISOString(),
				      heure_fin: new Date(new Date(end)).toISOString(),
				      matiere_id: ''
				  });
				  creneau_selectionne.$save()
				      .then( function () {
					  creneau_selectionne.dirty = true;
					  creneau_selectionne.start = start;
					  creneau_selectionne.heure_debut = start;
					  creneau_selectionne.heure_fin = end;

					  // durant le creneau_selectionne.$save() on perds regroupement_id
					  creneau_selectionne.regroupement_id = $scope.classe === null ? undefined : '' + $scope.classe;
					  creneau_selectionne.cahier_de_textes_id = $scope.classes[ 0 ].cahier_de_textes_id,
					  // 3. ouverture de la popup
					  $q.all( types_de_devoir, $scope.cours )
					      .then( function () {
						  creneau_selectionne.details = {
						      cours: $scope.cours,
						      devoirs: $scope.devoirs
						  };
						  ouvre_popup_edition( $scope.raw_data,
								       types_de_devoir, matieres_enseignees, $scope.classes,
								       creneau_selectionne, creneau_selectionne.matiere_id, creneau_selectionne.regroupement_id,
								       null, [],
								       popup_callback );
					      } );

					  $scope.emploi_du_temps.fullCalendar( 'unselect' );
				      } );
			      };

			      $scope.calendar.options.eventRender = function ( event, element ) {
				  // FIXME: manipulation du DOM dans le contrôleur, sale, mais obligé pour l'interprétation du HTML ?
				  element.find( '.fc-event-title' )
				      .append( ' - ' + event.regroupement.libelle + '<br>' + event.description );
			      };

			      filter_data = function( raw_data ) {
				  var filtered_data = raw_data;

				  // Filtrage sur une seule classe
				  if ( $scope.classe != null ) {
				      filtered_data = _( $scope.raw_data ).filter( function( creneau ) {
					  return creneau.regroupement_id == $scope.classe;
				      } );
				  }

				  if ( $scope.uniquement_mes_creneaux ) {
				      filtered_data = _( $scope.raw_data ).filter( function( creneau ) {
					  return creneau.enseignant_id === $scope.current_user.uid;
				      } );
				  }

				  return filtered_data;
			      };
			      break;

			  case 'ELV':
			  default:
			      $scope.calendar.options.eventRender = function( event, element ) {
				  // FIXME: manipulation du DOM dans le contrôleur, sale
				  // ajouter la description ici permet que l'HTML soit interprété
				  element.find('.fc-event-title').append( event.description );
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
