'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveCalendarCtrl',
		[ '$scope', '$rootScope', '$modal', 'APIEmploiDuTemps',
		  function ( $scope, $rootScope, $modal, APIEmploiDuTemps ) {
		      // popup d'affichage des détails
		      $scope.cours = {};
		      $scope.devoir = {};
		      $scope.affiche_details = function(  ) {
			  $modal.open({ templateUrl: 'views/modals/eleve.detail_emploi_du_temps.html',
					controller: modalInstanceCtrl,
					resolve: {
					    cours: function() { return $scope.cours; },
					    devoir: function() { return $scope.devoir; }
					}
				      });
		      };
		      var modalInstanceCtrl = function( $scope, $modalInstance, cours, devoir ) {
			  $scope.cours = cours;
			  $scope.devoir = devoir;

			  $scope.close = function() {
			      $modalInstance.close();
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
		      $scope.calendar.options.eventClick = function( event ) {
			  var event_data = _(event.source.events).findWhere({_id: event._id});
			  $scope.cours = event_data.details.cours;
			  if ( _($scope.cours).size() > 0 ) {
			      $scope.devoir = event_data.details.devoir;

			      $scope.affiche_details(  );
			  }
		      };


		      // population des créneaux d'emploi du temps avec les cours et devoirs éventuels
		      APIEmploiDuTemps.query( function( response ) {
			  $scope.calendar.events.push( response.map( function( event ) {

			      // TODO: mettre les détails cours et devoir dans un tableau à part pour popup
			      return { details: { cours: event.cours,
						  devoir: event.devoir },
				       allDay: false,
				       title: ''+event.matiere_id,
				       start: new Date( event.start ),
				       end: new Date( event.end ),
				       color: (_(event.devoir).size() > 0) ? $rootScope.theme.calendar.devoir : (_(event.cours).size() > 0) ? $rootScope.theme.calendar.saisie : $rootScope.theme.calendar.vide };
			  } ) );
		      });
		  }
		] );
