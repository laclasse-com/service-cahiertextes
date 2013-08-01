'use strict';

angular.module('publicAngularApp')
	.controller('PrincipalCtrl', function ($scope) {
		
	});

angular.module('publicAngularApp')
	.controller('PrincipalClassesCtrl', function ($scope, $http, EmploiDuTemps) {
		$scope.classes = [];
		EmploiDuTemps.getClasses().success( function( response ) {
			$scope.classes = response.classes;
		});
		$scope.classeCourante = $scope.classes[1];
		
		$scope.mois = [];
		EmploiDuTemps.getMois().success( function( response ) {
			$scope.mois = response.mois;
		});
		$scope.moisCourant = $scope.mois[1];
		
		$scope.matieres = [];
		EmploiDuTemps.getMatieres().success( function( response ) {
			$scope.matieres = response.matieres;
		});
		$scope.matiereCourante = $scope.matieres[1];
	});
angular.module('publicAngularApp')
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

angular.module('publicAngularApp')
	.controller('PrincipalEnseignantsCtrl', function ($scope, $http, EmploiDuTemps) {
		$scope.enseignants = [];
		EmploiDuTemps.getEnseignants().success(
			function( response ) {
				$scope.enseignants = response;
			});
		$scope.enseignant = "test";

		$scope.mois = [];
		EmploiDuTemps.getMois().success(
			function( response ) {
				$scope.mois = response.mois;
			});
		$scope.moisCourant = $scope.mois[1];

        $scope.gridEnseignants = {
			data: 'enseignants',
			enableCellEdit: true,
			plugins: [new ngGridFlexibleHeightPlugin()],
		    columnDefs: [
					{ field: 'name', displayName: 'Nom', cellTemplate: '<div><a href="#/principal/enseignant/{{row.getProperty(\'id\')}}">{{row.entity[col.field]}}</a></div>' },
					{ field: 'discipline', displayName: 'Discipline' },
					{ field: 'stats', displayName: 'Statistiques' }]
		};
		
	});
angular.module('publicAngularApp')
	.controller('PrincipalEnseignantsRadarChartCtrl', function ($scope, $http) {
		$scope.data = [
			[
				{axis: "strength", value: 13},
				{axis: "intelligence", value: 1},
				{axis: "charisma", value: 8},
				{axis: "dexterity", value: 4},
				{axis: "luck", value: 9}
			],[
				{axis: "strength", value: 3},
				{axis: "intelligence", value: 15},
				{axis: "charisma", value: 4},
				{axis: "dexterity", value: 1},
				{axis: "luck", value: 15}
			],[
				{axis: "strength", value: 5},
				{axis: "intelligence", value: 1},
				{axis: "charisma", value: 16},
				{axis: "dexterity", value: 10},
				{axis: "luck", value: 5}
			]
		];
		$scope.renderer = RadarChart.draw;
	});

angular.module('publicAngularApp')
	.controller('PrincipalEnseignantCtrl', function ($scope, $http, EmploiDuTemps) {
		$scope.classes = [];
		EmploiDuTemps.getClasses().success( function( response ) {
			$scope.classes = response.classes;
		});
	});
