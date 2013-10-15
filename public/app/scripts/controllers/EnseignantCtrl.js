'use strict';

angular.module('cahierDeTexteApp')
    .controller('EnseignantCtrl',
		[ '$scope', '$rootScope', '$modal', '$q', 'APIEmploiDuTemps', 'APIMatieres', 'APICours', 'APIDevoir', 'APITypesDeDevoir',
		  function ( $scope, $rootScope, $modal, $q, APIEmploiDuTemps, APIMatieres, APICours, APIDevoir, APITypesDeDevoir ) {
		      $scope.matieres = {};

		      // configuration du composant calendrier
		      $scope.calendar = { options: $rootScope.globalCalendarOptions,
					  events: [  ] };
		      $scope.calendar.options.defaultView = 'agendaWeek';
		      $scope.calendar.options.height = 600;
		      $scope.calendar.options.editable = false;
		      $scope.calendar.options.header = { left: 'title',
							 center: 'agendaDay agendaWeek month',
							 right: 'today prev,next' };

		      $scope.calendar.options.eventRender = function( event, element ) {
			  element.find('.fc-event-title').append( event.description );
		      };

		      // ouverture de la popup de création/édition
		      $scope.calendar.options.eventClick = function( event ) {
			  $scope.creneau = _(event.source.events).findWhere({_id: event._id});
			  $scope.matiere = event.title;

			  APITypesDeDevoir.query()
			      .$promise.then( function( response ) {
				  $scope.types_de_devoir = response;

				  APICours.get( { id: $scope.creneau.details.cours.id } )
				      .$promise
				      .then( function success( cours ) {
					  $scope.cours = cours;
					  $scope.cours.create = false;

					  APIDevoir.get( { id: $scope.creneau.details.devoir.id } )
					      .$promise
					      .then( function success( devoir ) {
						  $scope.devoir = devoir;
						  $scope.devoir.create = false;

						  $scope.ouvre_popup(  );
					      },
						     function error( raison ) {
							 console.log( 'Erreur ' + raison.status );
							 $scope.devoir = new APIDevoir({ cours_id: $scope.cours.id,
											 type_devoir_id: $scope.types_de_devoir[0].id });
							 $scope.devoir.create = true;
							 $scope.ouvre_popup(  );
						     });
				      },
					     function error( raison ) {
						 console.log( 'Erreur ' + raison.status );
						 $scope.cours = new APICours({
						     cahier_de_textes_id: $scope.creneau.details.cahier_de_textes_id,
						     creneau_emploi_du_temps_id: $scope.creneau.details.creneau_emploi_du_temps_id,
						     date_cours: $scope.creneau.start
						 });
						 $scope.cours.create = true;
						 $scope.devoir = new APIDevoir({ type_devoir_id: $scope.types_de_devoir[0].id });
						 $scope.devoir.create = true;
						 $scope.ouvre_popup(  );
					     });
			      });
		      };

		      // popup de création/édition
		      var modalInstanceCtrl = function( $scope, $rootScope, $modalInstance, matiere, cours, devoir, types_de_devoir ) {
			  // Attention, $scope ici est le scope de la popup, plus celui d'EnseignantCtrl !
			  $scope.matiere = matiere;
			  $scope.cours = cours;
			  $scope.devoir = devoir;
			  $scope.types_de_devoir = types_de_devoir;
			  $scope.tinyMCEOptions = $rootScope.tinyMCEOptions;

			  $scope.fermer = function() {
			      $modalInstance.close( { cours: $scope.cours,
						      devoir: $scope.devoir} );
			  };

			  $scope.valider = function() {
			      var promesse = $q.when(true);

			      if ( $scope.cours.contenu !== '' ) {
				  if ( $scope.cours.create ) {
				      promesse = $scope.cours.$save();
				  } else {
				      promesse = $scope.cours.$update();
				  }
			      }

			      promesse.then( function( cours ) {
				  $scope.cours = cours;
				  if ( $scope.devoir.contenu !== '' ) {
				      if ( $scope.devoir.create ) {
					  $scope.devoir.cours_id = $scope.cours.id;
					  console.log($scope.devoir)
					  $scope.devoir.$save();
				      } else {
					  $scope.devoir.$update();
				      }
				  }
			      });

			      $scope.fermer();
			  };
		      };

		      $scope.ouvre_popup = function(  ) {
			  $modal.open({ templateUrl: 'views/modals/enseignant/detail_emploi_du_temps.html',
					controller: modalInstanceCtrl,
					resolve: { matiere: function() { return $scope.matiere; },
						   cours: function() { return $scope.cours; },
						   devoir: function() { return $scope.devoir; },
						   types_de_devoir: function() { return $scope.types_de_devoir; } } })
			      .result.then( function ( objets ) {
				  var index = _($scope.calendar.events[0]).indexOf($scope.creneau);
				  var updated_event = $scope.update_fullCalendar_event( $scope.creneau, objets.cours, objets.devoir );
				  $scope.emploi_du_temps.fullCalendar( 'renderEvent', $scope.calendar.events[0][ index ] );
				      _.chain(updated_event)
					  .keys()
					  .reject(function( key ) {
					      return key == "title";
					  })
					  .each( function( propriete ) {
					      $scope.calendar.events[0][ index ][ propriete ] = updated_event[ propriete ];
					  });
			      });
		      };

		      // helper
		      $scope.update_fullCalendar_event = function( event, cours, devoir ) {
			  var calendar_event = { details: { matiere_id: event.details.matiere_id,
							    cahier_de_textes_id: event.details.cahier_de_textes_id,
							    creneau_emploi_du_temps_id: event.details.creneau_emploi_du_temps_id,
							    cours: cours,
							    devoir: devoir },
						 allDay: false,
						 title: '',
						 description: '',
						 start: event.start,
						 end: event.end,
						 color: '' };

			  // choix de la couleur
			  if ( _(cours).size() > 0 ) {
			      calendar_event.color = ( _(devoir).size() > 0 ) ? $rootScope.theme.calendar.devoir : $rootScope.theme.calendar.saisie;
			  } else {
			      calendar_event.color = $rootScope.theme.calendar.vide;
			  }

			  // composition de la description
			  if ( _(cours).size() > 0 ) {
			      calendar_event.description += '<br><span style="color:' + $rootScope.calendar.couleurs.cours + '">';
			      calendar_event.description += cours.contenu.substring( 0, $rootScope.calendar.cours_max_length );
			      calendar_event.description += cours.contenu.length > $rootScope.calendar.cours_max_length ? '…' : '';
			      calendar_event.description += '</span>';
			      if ( _(devoir).size() > 0 ) {
				  calendar_event.description += '<br><span style="color:' + $rootScope.calendar.couleurs.devoir + '">';
				  calendar_event.description += devoir.contenu.substring( 0, $rootScope.calendar.devoir_max_length );
				  calendar_event.description += devoir.contenu.length > $rootScope.calendar.devoir_max_length ? '…' : '';
				  calendar_event.description += '</span>';
			      }
			  }

			  // composition du titre
			  if ( $scope.matieres[ event.details.matiere_id ] === undefined ) {
			      $scope.matieres[ event.details.matiere_id ] = APIMatieres.get({ matiere_id: event.details.matiere_id }).$promise;
			  }
			  $scope.matieres[ event.details.matiere_id ].then( function success( response ) {
			      calendar_event.title = response.libelle_long;
			  });

			  return calendar_event;
		      };

		      $scope.assemble_fullCalendar_event = function( item_emploi_du_temps ) {
			  return $scope.update_fullCalendar_event( { details: { matiere_id: item_emploi_du_temps.matiere_id,
										cahier_de_textes_id: item_emploi_du_temps.cahier_de_textes_id,
										creneau_emploi_du_temps_id: item_emploi_du_temps.creneau_emploi_du_temps_id },
								     start: new Date( item_emploi_du_temps.start ),
								     end: new Date( item_emploi_du_temps.end ) },
								   item_emploi_du_temps.cours,
								   item_emploi_du_temps.devoir );
		      };

		      // population des créneaux d'emploi du temps avec les cours et devoirs éventuels
		      APIEmploiDuTemps.query( function( response ) {
			  $scope.calendar.events.push( response.map( function( event ) {
			      return $scope.assemble_fullCalendar_event( event );
			  } ) );
		      });
		  } ] );
