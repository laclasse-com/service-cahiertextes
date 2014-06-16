'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveEmploiDuTempsCtrl',
		[ '$scope', '$modal', 'CALENDAR_OPTIONS', 'CALENDAR_PARAMS', 'API', 'Annuaire', 'EmploisDuTemps', 'User',
		  function ( $scope, $modal, CALENDAR_OPTIONS, CALENDAR_PARAMS, API, Annuaire, EmploisDuTemps, User ) {
		      $scope.creneau_selectionne = {};

		      // popup d'affichage des détails
		      var ouvre_popup_details = function( titre, cours, devoirs ) {
			  $modal.open( { templateUrl: 'app/views/eleve/detail_emploi_du_temps.html',
					 controller: 'PopupEmploiDuTempsDisplayCtrl',
					 resolve: { titre: function() { return titre; },
						    cours: function() { return cours; },
						    devoirs: function() { return devoirs; } } }
				     ).result.then( function ( scope_popup ) {
					 _(scope_popup.devoirs).each(function(devoir) {
					     _($scope.calendar.events[0]).findWhere({type: 'devoir', id: devoir.id}).className = devoir.fait ? ' saisie-devoirs-fait' : ' saisie-devoirs';
					 });
					 $scope.emploi_du_temps.fullCalendar( 'renderEvent', $scope.creneau_selectionne );
				     });
		      };

		      // consommation des données
		      var retrieve_data = function( from_date, to_date ) {
			  User.get_user().then( function( response ) {
			      $scope.current_user = response.data;

			      var fullCalendarize_event = function( item_emploi_du_temps ) {
				  var Calendar_event = function( event, item ) {
				      var fc_event = this; //pour pouvoir le référencé dans les .then()
				      this.details = { cours: event.cours,
						       devoirs: event.devoirs };
				      this.allDay = false;
				      this.title = '';
				      this.description = '';
				      this.color = '';
				      this.type = ( _(item).has( 'fait' ) ) ? 'devoir': 'cours';
				      if ( this.type === 'cours' ) {
					  item.start = event.start;
					  item.end = event.end;
					  this.className = 'saisie-invalide';
					  if ( event.matiere_id.length > 0 ) {
					      Annuaire.get_matiere( event.matiere_id ).$promise.then( function success( response ) {
						  fc_event.title = response.libelle_long;
					      });
					  }
				      } else {
					  this.className = item.fait ? 'saisie-devoirs-fait' : 'saisie-devoirs';

					  API.get_type_de_devoir( { id: item.type_devoir_id } )
					      .$promise.then( function success( response ) {
						  fc_event.title = response.label;
					      });
				      }
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
				  var events = [];

				  // traitement du cours
				  events.push( new Calendar_event( item_emploi_du_temps, item_emploi_du_temps.cours ) );

				  // traitement des devoirs
				  _(item_emploi_du_temps.devoirs).each( function( devoir ) {
				      events.push( new Calendar_event( item_emploi_du_temps, devoir ) );
				  });

				  return events;
			      };

			      EmploisDuTemps.query(
				  { debut: from_date,
				    fin: to_date,
				    uai: $scope.current_user.profil_actif.uai },
				  function( response ) {
				      $scope.calendar.events[0] = _.chain( response )
					  .map( function( event ) {
					      return fullCalendarize_event( event );
					  } )
					  .flatten()
					  .value();
				  });
			  });
		      };

		      // configuration du composant calendrier
		      $scope.calendar = { options: CALENDAR_OPTIONS,
					  events: [  ] };
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
		      $scope.calendar.options.viewRender = function( view, element ) {
			  // population des créneaux d'emploi du temps avec les cours et devoirs éventuels
			  retrieve_data( view.visStart, view.visEnd );
		      };
		  } ] );
