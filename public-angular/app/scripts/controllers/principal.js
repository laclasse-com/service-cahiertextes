'use strict';

angular.module('publicAngularApp')
	.controller('PrincipalCtrl', function ($scope) {
		
	});

angular.module('publicAngularApp')
	.controller('PrincipalClassesCtrl', function ($scope) {
		$scope.classes = ['6ème A',
						  '4ème O',
						  '5ème L'];
		$scope.classeCourante = $scope.classes[1];
		$scope.mois = ['January',
					   'February',
					   'March',
					   'April',
					   'May',
					   'June',
					   'July',
					   'August',
					   'September',
					   'October',
					   'November',
					   'December'];
		$scope.moisCourant = $scope.mois[1];
		$scope.matieres = ['Français','Mathématiques', 'Équilibrisme'];
		$scope.matiereCourante = $scope.matieres[1];
		$scope.chartData = [[
			['6ème A', 12],['4ème O', 9], ['5ème L', 14], 
			['Out of home', 16],['Commuting', 7], ['Orientation', 9]
		]];
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
