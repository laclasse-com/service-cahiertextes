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
		      $scope.calendar.options.height = 600;
		      $scope.calendar.options.editable = false;
		      $scope.calendar.options.header = { left: 'title',
							 center: 'agendaDay agendaWeek month',
							 right: 'today prev,next' };

		      APIEmploiDuTemps.query( function( response ) {
			  $scope.calendar.events.push( response.map( function( event ) {
			      return { title: event.title,
				       start: new Date( event.start ),
				       end: new Date( event.end ),
				       allDay: event.allDay,
				       url: event.url,
				       color: event.color };
			  } ) );
		      });
		  }
		] );
