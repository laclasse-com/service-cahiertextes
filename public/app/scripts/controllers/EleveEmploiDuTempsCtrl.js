'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveEmploiDuTempsCtrl',
		[ '$scope', '$rootScope', '$modal', 'EmploisDuTemps', 'Matieres', 'TypesDeDevoir',
		  function ( $scope, $rootScope, $modal, EmploisDuTemps, Matieres, TypesDeDevoir ) {
		      var eleve_id = 1;

		      $scope.matieres = {};
		      $scope.types_de_devoir = {};

		      // configuration du composant calendrier
		      $scope.calendar = { options: $rootScope.globalCalendarOptions,
					  events: [  ] };
		      $scope.calendar.options.defaultView = 'agendaWeek';
		      $scope.calendar.options.height = 600;
		      $scope.calendar.options.editable = false;
		      $scope.calendar.options.header = { left: 'title',
							 center: 'agendaDay agendaWeek month',
							 right: 'today prev,next' };

		      // ajouter la description ici permet que l'HTML soit interprété
		      $scope.calendar.options.eventRender = function( event, element ) {
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

		      // popup d'affichage des détails
		      $scope.cours = {};
		      $scope.devoirs = [];
		      $scope.affiche_details = function(  ) {
			  $modal.open({ templateUrl: 'views/modals/eleve/detail_emploi_du_temps.html',
					controller: modalInstanceCtrl,
					resolve: { matiere: function() { return $scope.matiere; },
						   cours: function() { return $scope.cours; },
						   devoirs: function() { return $scope.devoirs; } } })
			      .result.then( function ( devoirs ) {
				  _(devoirs).each(function(devoir) {
				      _($scope.calendar.events[0]).findWhere({type: 'devoir', id: devoir.id}).color = devoir.fait ? $rootScope.theme.calendar.devoir_fait : $rootScope.theme.calendar.devoir;
				  });
				  $scope.emploi_du_temps.fullCalendar( 'renderEvent', $scope.creneau );
			      });
		      };

		      var modalInstanceCtrl = function( $scope, $modalInstance, Devoirs, matiere, cours, devoirs ) {
			  $scope.matiere = matiere;
			  $scope.cours = cours;
			  $scope.devoirs = devoirs;

			  $scope.fait = function( devoir_id ) {
			      Devoirs.fait({ id: devoir_id,
					     eleve_id: eleve_id },
					   function() {
					       // FIXME
					       _(devoirs).findWhere({id: devoir_id}).fait = true;
					   });
			  };

			  $scope.fermer = function() {
			      $modalInstance.close( devoirs );
			  };
		      };

		      // consommation des données
		      $scope.assemble_fullCalendar_event = function( item_emploi_du_temps ) {
			  var Calendar_event_template = function() { this.details = { cours: item_emploi_du_temps.cours,
										      devoirs: item_emploi_du_temps.devoirs };
								     this.allDay = false;
								     this.title = '';
								     this.description = '';
								     this.start = new Date( item_emploi_du_temps.start );
								     this.end = new Date( item_emploi_du_temps.end );
								     this.color = ''; };
			  var events = [];

			  // traitement du cours
			  var cours_event = new Calendar_event_template();
			  cours_event.type = 'cours';
			  cours_event.id = item_emploi_du_temps.cours.id;

			  // choix de la couleur
			  if ( _(item_emploi_du_temps.cours).size() > 0 ) {
			      cours_event.color = $rootScope.theme.calendar.saisie;
			  } else {
			      cours_event.color = $rootScope.theme.calendar.vide;
			  }

			  // composition de la description
			  if ( _(item_emploi_du_temps.cours).size() > 0 ) {
			      cours_event.description += '<br><span style="color:' + $rootScope.calendar.couleurs.cours + '">';
			      cours_event.description += item_emploi_du_temps.cours.contenu.substring( 0, $rootScope.calendar.cours_max_length );
			      cours_event.description += item_emploi_du_temps.cours.contenu.length > $rootScope.calendar.cours_max_length ? '…' : '';
			      cours_event.description += '</span>';
			  }

			  // composition du titre
			  if ( $scope.matieres[ item_emploi_du_temps.matiere_id ] === undefined ) {
			      $scope.matieres[ item_emploi_du_temps.matiere_id ] = Matieres.get({ matiere_id: item_emploi_du_temps.matiere_id }).$promise;
			  }
			  $scope.matieres[ item_emploi_du_temps.matiere_id ].then( function success( response ) {
			      cours_event.title = response.libelle_long;
			  });

			  events.push( cours_event );

			  // traitement des devoirs
			  if ( _(item_emploi_du_temps.devoirs).size() > 0 ) {
			      _(item_emploi_du_temps.devoirs).each( function( devoir ) {
				  var devoir_event = new Calendar_event_template();
				  devoir_event.type = 'devoir';
				  devoir_event.id = devoir.id;

				  devoir_event.color = devoir.fait ? $rootScope.theme.calendar.devoir_fait : $rootScope.theme.calendar.devoir;
				  devoir_event.start = new Date( devoir.start );
				  devoir_event.end = new Date( devoir.end );

				  // composition de la description
				  devoir_event.description += '<br><span style="color:' + $rootScope.calendar.couleurs.devoir + '">';
				  devoir_event.description += devoir.contenu.substring( 0, $rootScope.calendar.devoir_max_length );
				  devoir_event.description += devoir.contenu.length > $rootScope.calendar.devoir_max_length ? '…' : '';
				  devoir_event.description += '</span>';

				  // composition du titre
				  if ( $scope.types_de_devoir[ devoir.type_devoir_id ] === undefined ) {
				      $scope.types_de_devoir[ devoir.type_devoir_id ] = TypesDeDevoir.get({ id: devoir.type_devoir_id }).$promise;
				  }
				  $scope.types_de_devoir[ devoir.type_devoir_id ].then( function success( response ) {
				      devoir_event.title = response.label;
				  });

				  events.push( devoir_event );
			      });
			  }

			  return events;
		      };

		      // population des créneaux d'emploi du temps avec les cours et devoirs éventuels
		      EmploisDuTemps.query( function( response ) {
			  $scope.calendar.events.push( response.map( function( event ) {
			      return $scope.assemble_fullCalendar_event( event );
			  } ) );
			  $scope.calendar.events[0] = _($scope.calendar.events[0]).flatten();
		      });
		  } ] );
