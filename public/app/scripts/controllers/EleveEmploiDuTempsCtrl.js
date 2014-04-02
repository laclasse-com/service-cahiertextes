'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveEmploiDuTempsCtrl',
		[ '$scope', '$modal', 'THEME', 'CALENDAR_OPTIONS', 'CALENDAR_PARAMS', 'API', 'Annuaire', 'EmploisDuTemps',
		  function ( $scope, $modal, THEME, CALENDAR_OPTIONS, CALENDAR_PARAMS, API, Annuaire, EmploisDuTemps ) {
		      $scope.types_de_devoir = {};

		      // configuration du composant calendrier
		      $scope.calendar = { options: CALENDAR_OPTIONS,
					  events: [  ] };
		      $scope.calendar.options.defaultView = 'agendaWeek';
		      $scope.calendar.options.editable = false;
		      $scope.calendar.options.eventRender = function( event, element ) {
			  // ajouter la description ici permet que l'HTML soit interprété
			  element.find('.fc-event-title').append( event.description );
		      };
		      $scope.calendar.options.eventClick = function( event ) {
			  $scope.creneau = _(event.source.events).findWhere({_id: event._id});
			  $scope.matiere = event.title;
			  $scope.cours = $scope.creneau.details.cours;
			  if ( _($scope.cours).size() > 0 ) {
			      $scope.devoirs = $scope.creneau.details.devoirs;
			      $scope.affiche_details(  );
			  }
		      };
		      $scope.calendar.options.viewRender = function( view, element ) {
			  // population des créneaux d'emploi du temps avec les cours et devoirs éventuels
			  $scope.retrieve_data( view.visStart, view.visEnd );
		      };

		      // popup d'affichage des détails
		      $scope.cours = {};
		      $scope.devoirs = [];
		      $scope.affiche_details = function(  ) {
			  $modal.open( { templateUrl: 'app/views/modals/eleve/detail_emploi_du_temps.html',
					 resolve: { matiere: function() { return $scope.matiere; },
						    cours: function() { return $scope.cours; },
						    devoirs: function() { return $scope.devoirs; } },
					 controller: [ '$scope', '$modalInstance', 'Devoirs', 'matiere', 'cours', 'devoirs',
						       function( $scope, $modalInstance, Devoirs, matiere, cours, devoirs ) {
							   $scope.matiere = matiere;
							   $scope.cours = cours;
							   $scope.devoirs = devoirs;

							   $scope.fait = function( devoir_id ) {
							       Devoirs.fait({ id: devoir_id },
									    function() {
										_(devoirs).findWhere({id: devoir_id}).fait = true;
									    });
							   };

							   $scope.fermer = function() {
							       $modalInstance.close( devoirs );
							   };
						       } ] }
				     ).result.then( function ( devoirs ) {
					 _(devoirs).each(function(devoir) {
					     _($scope.calendar.events[0]).findWhere({type: 'devoir', id: devoir.id}).color = devoir.fait ? THEME.calendar.devoir_fait : THEME.calendar.devoir;
					 });
					 $scope.emploi_du_temps.fullCalendar( 'renderEvent', $scope.creneau );
				     });
		      };

		      // consommation des données
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
			      }
			      this.start = new Date( item.start );
			      this.end = new Date( item.end );

			      if ( this.type === 'cours' ) {
				  this.color = THEME.calendar.saisie;
				  if ( event.matiere_id.length > 0 ) {
				      Annuaire.get_matiere( event.matiere_id ).$promise.then( function success( response ) {
					  fc_event.title = response.libelle_long;
				      });
				  }
			      } else {
				  this.color = item.fait ? THEME.calendar.devoir_fait : THEME.calendar.devoir;

				  API.get_type_de_devoir( { id: item.type_devoir_id } )
				      .$promise.then( function success( response ) {
					  fc_event.title = response.label;
				      });
			      }

			      if ( _(item).has( 'contenu' ) && item.contenu.length > 0 ) {
				  this.description += '<br><span style="color:' + CALENDAR_PARAMS.couleurs[ this.type ] + '">';
				  this.description += item.contenu.substring( 0, CALENDAR_PARAMS.max_length );
				  this.description += item.contenu.length > CALENDAR_PARAMS.max_length ? '…' : '';
				  this.description += '</span>';
				  this.className = 'clickable-event';
				  this.id = item.id;
			      } else {
				  this.color = THEME.calendar.vide;
				  this.className = 'un-clickable-event';
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

		      $scope.retrieve_data = function( from_date, to_date ) {
			  EmploisDuTemps.query( { debut: from_date, fin: to_date },
						function( response ) {
						    $scope.calendar.events[0] = _.chain( response )
							.map( function( event ) {
							    return fullCalendarize_event( event );
							} )
							.flatten()
							.value();
						});
		      };
		  } ] );
