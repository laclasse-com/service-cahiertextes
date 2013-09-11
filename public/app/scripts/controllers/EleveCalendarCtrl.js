'use strict';

angular.module('cahierDeTexteApp')
	.controller('EleveCalendarCtrl', function ($scope) {
		var date = new Date();
		var d = date.getDate();
		var m = date.getMonth();
		var y = date.getFullYear();
		/* event source that contains custom events on the scope */
		$scope.events = [
			{title: 'All Day Event',start: new Date(y, m, 1)},
			{title: 'Long Event',start: new Date(y, m, d - 5),end: new Date(y, m, d - 2)},
			{id: 999,title: 'Repeating Event',start: new Date(y, m, d - 3, 16, 0),allDay: false},
			{id: 999,title: 'Repeating Event',start: new Date(y, m, d + 4, 16, 0),allDay: false},
			{title: 'Birthday Party',start: new Date(y, m, d + 1, 19, 0),end: new Date(y, m, d + 1, 22, 30),allDay: false},
			{title: 'Click for Google',start: new Date(y, m, 28),end: new Date(y, m, 29),url: 'http://google.com/'}
		];
		/* alert on eventClick */
		$scope.alertEventOnClick = function( date ){
			$scope.$apply(function(){
				$scope.alertMessage = ('Day Clicked ' + date);
			});
		};
		/* alert on Drop */
		$scope.alertOnDrop = function(event, dayDelta){
			$scope.$apply(function(){
				$scope.alertMessage = ('Event Droped to make dayDelta ' + dayDelta);
			});
		};
		/* alert on Resize */
		$scope.alertOnResize = function(event, dayDelta, minuteDelta ){
			$scope.$apply(function(){
				$scope.alertMessage = ('Event Resized to make dayDelta ' + minuteDelta);
			});
		};
		/* add and removes an event source of choice */
		$scope.addRemoveEventSource = function(sources,source) {
			var canAdd = 0;
			angular.forEach(sources,function(value, key){
				if(sources[key] === source){
					sources.splice(key,1);
					canAdd = 1;
				}
			});
			if(canAdd === 0){
				sources.push(source);
			}
		};
		/* add custom event*/
		$scope.addEvent = function() {
			$scope.events.push({
				title: 'Open Sesame',
				start: new Date(y, m, 28),
				end: new Date(y, m, 29),
				className: ['openSesame']
			});
		};
		/* remove event */
		$scope.remove = function(index) {
			$scope.events.splice(index,1);
		};
		/* Change View */
		$scope.changeView = function(view, calendar) {
			calendar.fullCalendar('changeView',view);
		};
		/* config object */
		$scope.uiConfig = {
			calendar:{
				height: 450,
				editable: true,
				header:{
					left: 'title',
					center: '',//'month basicWeek basicDay agendaWeek agendaDay',
					right: 'basicDay basicWeek today prev,next'
				},
				dayClick: $scope.alertEventOnClick,
				eventDrop: $scope.alertOnDrop,
				eventResize: $scope.alertOnResize
			}
		};
		/* event sources array*/
		$scope.eventSources = [$scope.events];
	})
	.controller('EleveCtrl', function ($scope) {
		$scope.partToShow = 'Cours';
	});
