'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveEmploiDuTempsCtrl',
		[ '$scope', '$modal', 'CALENDAR_OPTIONS', 'CALENDAR_PARAMS', 'API', 'Annuaire', 'EmploisDuTemps', 'User',
		  function ( $scope, $modal, CALENDAR_OPTIONS, CALENDAR_PARAMS, API, Annuaire, EmploisDuTemps, User ) {
		      // configuration du composant calendrier
		      $scope.calendar = { options: CALENDAR_OPTIONS,
					  events: [  ] };
		      $scope.calendar.options.eventRender = function( event, element ) {
			  // FIXME: manipulation du DOM dans le contrôleur, sale
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
			  $modal.open( { templateUrl: 'app/views/eleve/detail_emploi_du_temps.html',
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
					     _($scope.calendar.events[0]).findWhere({type: 'devoir', id: devoir.id}).className = devoir.fait ? ' saisie-devoirs-fait' : ' saisie-devoirs';
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

		      $scope.retrieve_data = function( from_date, to_date ) {
			  User.get_user().then( function( response ) {
			      $scope.current_user = response.data;

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
		  } ] );
