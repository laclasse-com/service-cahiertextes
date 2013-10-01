'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveCalendarCtrl',
		[ '$scope', '$rootScope',
		  function ( $scope, $rootScope ) {
		      var date = new Date();
		      var d = date.getDate();
		      var m = date.getMonth();
		      var y = date.getFullYear();

		      /* config object */
		      $scope.calendar = {
			  options: $rootScope.globalCalendarOptions,
			  events: [[
			      { title: 'Birthday Party',
				start: new Date(y, m, d, 19, 0),
				end: new Date(y, m, d, 22, 30),
				allDay: false,
				url: 'http://laclasse.com',
				color: '#778899'}
			  ]]
		      };
		      $scope.calendar.options.height = 600;
		      $scope.calendar.options.editable = false;
		      $scope.calendar.options.header = { left: 'title',
							 center: 'agendaDay agendaWeek month',
							 right: 'today prev,next' };
		  }
		] );
