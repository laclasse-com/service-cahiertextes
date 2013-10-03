'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveCalendarCtrl',
		[ '$scope', '$rootScope', 'APIEmploiDuTemps',
		  function ( $scope, $rootScope, APIEmploiDuTemps ) {
		      /* config object */
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

		      APIEmploiDuTemps.query( function( response ) {
			  $scope.calendar.events.push( response.map( function( event ) {
			      return { allDay: false,
				       title: ''+event.matiere_id,
				       start: new Date( event.start ),
				       end: new Date( event.end ),
				       url: (event.cours_id > 0) ? 'javascript:alert(' + event.cours_id + ')' : '',
				       color: (event.devoir_id > 0) ? $rootScope.theme.calendar.devoir : (event.cours_id > 0) ? $rootScope.theme.calendar.saisie : $rootScope.theme.calendar.vide };
			  } ) );
		      });
		  }
		] );
