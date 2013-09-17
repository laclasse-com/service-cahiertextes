'use strict';

angular.module('cahierDeTexteApp').
    controller('PrincipalClassesChartCtrl', [ '$scope', function ($scope) {
	$scope.chart = {};
	$scope.chart.data = [];
	$scope.chart.options = {};
    } ] );
