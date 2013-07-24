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
	.controller('PrincipalEnseignantsCtrl', function ($scope, $http) {
		$scope.enseignants = [];
		$http.get('mocks/enseignants.json').success( function( response ) {
			$scope.enseignants = response.enseignants;
		});
		
        $scope.gridEnseignants = { data: 'enseignants',
								   enableCellEdit: true,
								   plugins: [new ngGridFlexibleHeightPlugin()] };
		
	});

angular.module('publicAngularApp')
	.controller('PrincipalEnseignantCtrl', function ($scope, $http) {
		$scope.classes = [];
		$http.get('mocks/classes.json').success( function( response ) {
			$scope.classes = response.classes;
		});
	});
