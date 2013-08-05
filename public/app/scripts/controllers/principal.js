'use strict';

angular.module('cahierDeTexteApp')
	.controller('PrincipalCtrl', function ($scope) {
		
	});

angular.module('cahierDeTexteApp')
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

angular.module('cahierDeTexteApp')
	.controller('PrincipalEnseignantsCtrl', function ($scope, $http, EmploiDuTemps) {
		$scope.enseignants = [];
		$scope.radar = {};
		$scope.radar.data = [];
		$scope.radar.renderer = RadarChart.draw;

		EmploiDuTemps.getEnseignants().success(
			function( response ) {
				$scope.enseignants = response;
				$scope.radar.data.push( $scope.enseignants.map( function(e){return {axis: e.name, value: e.total};}));
				$scope.radar.data.push( $scope.enseignants.map( function( e ){ return { axis: e.name, value: e.stats }; } ) );
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

angular.module('cahierDeTexteApp')
	.controller('PrincipalEnseignantCtrl', function ($scope, $http, EmploiDuTemps) {
		$scope.classes = [];
		EmploiDuTemps.getClasses().success( function( response ) {
			$scope.classes = response.classes;
		});
	});


