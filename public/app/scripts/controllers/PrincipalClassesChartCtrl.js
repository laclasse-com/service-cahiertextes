'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalClassesChartCtrl', function ($scope, $http) {
	$scope.chart = {};
	$scope.chart.data =  [[
	    ['Heavy Industry', 12],['Retail', 9], ['Light Industry', 14],
	    ['Out of home', 16],['Commuting', 7], ['Orientation', 9]
	]];
	$scope.chart.options = {
	    seriesDefaults: {
		// Make this a pie chart.
		renderer: jQuery.jqplot.PieRenderer,
		rendererOptions: {
		    // Put data labels on the pie slices.
		    // By default, labels show the percentage of the slice.
		    showDataLabels: true
		}
	    },
	    legend: { show:true, location: 'e' }
	};
    });
