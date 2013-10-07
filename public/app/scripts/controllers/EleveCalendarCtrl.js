'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveCalendarCtrl',
		[ '$scope', '$rootScope', '$modal', 'APIEmploiDuTemps',
		  function ( $scope, $rootScope, $modal, APIEmploiDuTemps ) {
		      // popup d'affichage des détails
		      $scope.cours = {};
		      $scope.devoir = {};
		      $scope.affiche_details = function(  ) {
			  var modalInstance = $modal.open({ templateUrl: 'views/modals/eleve.detail_emploi_du_temps.html',
							    controller: modalInstanceCtrl,
							    resolve: {
								matiere: function() { return $scope.matiere; },
								cours: function() { return $scope.cours; },
								devoir: function() { return $scope.devoir; }
							    }
							  });
			  modalInstance.result.then( function ( fait ) {
			      if ( fait != -1 ) {
				  $scope.creneau.color = fait ? $rootScope.theme.calendar.devoir_fait : $rootScope.theme.calendar.devoir;
			      }
			      $scope.emploi_du_temps.fullCalendar( 'renderEvent', $scope.creneau );
			  });
		      };
		      var modalInstanceCtrl = function( $scope, $modalInstance, APIDevoir, matiere, cours, devoir ) {
			  $scope.matiere = matiere;
			  $scope.cours = cours;
			  $scope.devoir = devoir;

			  $scope.fait = function() {
			      APIDevoir.fait({ id: devoir.id },
					     function() { devoir.fait = true; });
			  };

			  $scope.close = function() {
			      if ( _(devoir).size() > 0 ) {
				  $modalInstance.close( devoir.fait );
			      } else {
				  $modalInstance.close( -1 );
			      }
			  };
		      };

		      // configuration du composant calendrier
		      $scope.calendar = {
			  options: $rootScope.globalCalendarOptions,
			  events: [  ]
		      };
		      $scope.calendar.options.defaultView = 'agendaWeek';
		      $scope.calendar.options.height = 600;
		      $scope.calendar.options.editable = false;
		      $scope.calendar.options.header = { left: 'title',
							 center: 'agendaDay agendaWeek month',
							 right: 'today prev,next' };
		      $scope.calendar.options.eventRender = function( event, element ) {
			  if ( $scope.emploi_du_temps.fullCalendar( 'getView' ).name == 'agendaDay') {
			      if ( _(event.details.cours).size() > 0 ) {
				  var contenu_cellule = '<div class="cdt-agendaDay-container col-md-12">';
				  contenu_cellule += '  <div class="cdt-agendaDay-event col-md-12">';
				  contenu_cellule += '    <button type="button" disabled class="btn btn-primary btn-xs col-md-1">' + event.title + '</button>';
				  contenu_cellule += '    <div id="cours' + event.details.cours.id + '" class="col-md-4 cdt-agendaDay-cours">';
				  contenu_cellule += event.details.cours.contenu;
				  contenu_cellule += '    </div>';

				  if ( _(event.details.devoir).size() > 0 ) {
				      contenu_cellule += '    <span class="col-md-1">Taf <span class="glyphicon glyphicon-chevron-right"></span></span>';
				      contenu_cellule += '    <span class="col-md-1"><span class="glyphicon glyphicon-chevron-left"> Cours</span></span>';
				      contenu_cellule += '    <div id="devoir' + event.details.devoir.id + '" class="col-md-5 ';
				      if ( event.details.devoir.fait ) {
					  contenu_cellule += 'cdt-agendaDay-devoir-fait';
				      } else {
					  contenu_cellule += 'cdt-agendaDay-devoir';
				      }
				      contenu_cellule += '">';
				      contenu_cellule += event.details.devoir.contenu;
				      contenu_cellule += '    </div>';
				  }

				  contenu_cellule += '  </div>';
				  contenu_cellule += '</div>';

				  element.find('.fc-event-title').html( contenu_cellule );
			      }
			  } else  {
			      element.find('.fc-event-title').append( event.description );
			  }
		      };
		      $scope.calendar.options.eventClick = function( event, jsEvent ) {
			  console.log( jsEvent )
			  $scope.creneau = _(event.source.events).findWhere({_id: event._id});
			  $scope.matiere = event.title;
			  $scope.cours = $scope.creneau.details.cours;
			  if ( _($scope.cours).size() > 0 ) {
			      $scope.devoir = $scope.creneau.details.devoir;

			      $scope.affiche_details(  );
			  }
		      };

		      // population des créneaux d'emploi du temps avec les cours et devoirs éventuels
		      APIEmploiDuTemps.query( function( response ) {
			  $scope.calendar.events.push( response.map( function( event ) {
			      var couleur = '';
			      if ( _(event.cours).size() > 0 ) {
				  if ( _(event.devoir).size() > 0 ) {
				      if ( event.devoir.fait ) {
					  couleur = $rootScope.theme.calendar.devoir_fait;
				      } else {
					  couleur = $rootScope.theme.calendar.devoir;
				      }
				  } else {
				      couleur = $rootScope.theme.calendar.saisie;
				  }
			      } else {
				  couleur = $rootScope.theme.calendar.vide;
			      }

			      var description = '';
			      if ( _(event.cours).size() > 0 ) {
				  description += '<br><span style="color:' + $rootScope.calendar.couleurs.cours + '">';
				  description += event.cours.contenu.substring( 0, $rootScope.calendar.cours_max_length );
				  description += event.cours.contenu.length > $rootScope.calendar.cours_max_length ? '…' : '';
				  description += '</span>';
				  if ( _(event.devoir).size() > 0 ) {
				      description += '<br><span style="color:' + $rootScope.calendar.couleurs.devoir + '">';
				      description += event.devoir.contenu.substring( 0, $rootScope.calendar.devoir_max_length );
				      description += event.devoir.contenu.length > $rootScope.calendar.devoir_max_length ? '…' : '';
				      description += '</span>';
				  }
			      }

			      return { details: { cours: event.cours,
						  devoir: event.devoir },
				       allDay: false,
				       title: '' + event.matiere_id,
				       description: description,
				       start: new Date( event.start ),
				       end: new Date( event.end ),
				       color: couleur };
			  } ) );
		      });
		  }
		] );
