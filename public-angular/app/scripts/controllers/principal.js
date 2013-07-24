'use strict';

angular.module('publicAngularApp')
	.controller('PrincipalCtrl', function ($scope) {
		
	});

angular.module('publicAngularApp')
	.controller('PrincipalClassesCtrl', function ($scope) {
		$scope.classes = ['6ème A', '4ème O', '5ème L'];
		$scope.classeCourante = $scope.classes[1];
		
		$scope.mois = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
		$scope.moisCourant = $scope.mois[1];
		
		$scope.matieres = ['Français','Mathématiques', 'Équilibrisme'];
		$scope.matiereCourante = $scope.matieres[1];
	});
angular.module('publicAngularApp')
	.controller('PrincipalClassesChartCtrl', function ($scope) {
		// $scope.data =  [[
		// 	['Heavy Industry', 12],['Retail', 9], ['Light Industry', 14],
		// 	['Out of home', 16],['Commuting', 7], ['Orientation', 9]
		// ]];
		$scope.chart = {};
		$scope.chart.data = [ [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] ];
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
	.controller('PrincipalEnseignantsCtrl', function ($scope) {
		$scope.enseignants = [
			'M. Raymond',
			'Melle Roux',
			'Maitre Hibou'
		];
	});

angular.module('publicAngularApp')
	.controller('PrincipalEnseignantCtrl', function ($scope) {
		$scope.classes = [
			'3ème A',
			'6ème ZX'
		];
	});
