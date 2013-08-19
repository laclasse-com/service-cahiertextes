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
		$scope.annee = [];

		$scope.radar = {
			data: [],
			renderer: RadarChart.draw
		};
        $scope.gridEnseignants = {
			data: 'enseignants',
			enableCellEdit: true,
			plugins: [new ngGridFlexibleHeightPlugin()],
		    columnDefs: [
					{ field: 'name', displayName: 'Nom', cellTemplate: '<div><a href="#/principal/enseignant/{{row.getProperty(\'id\')}}">{{row.entity[col.field]}}</a></div>' },
					{ field: 'discipline', displayName: 'Discipline' },
					{ field: 'stats', displayName: 'Statistiques' }]
		};

		$scope.loadData = function() {
			EmploiDuTemps.getEnseignants().success(
				function( response ) {
					$scope.enseignants = response;
					$scope.radar.data.push( $scope.enseignants.map( function( e ) {
						return { axis: e.name, value: e.total };
					} ) );
					$scope.radar.data.push( $scope.enseignants.map( function( e ) {
						return { axis: e.name, value: e.stats };
					} ) );
				});
			// $scope.enseignant = $scope.enseignants[0];

			EmploiDuTemps.getMois().success(
				function( response ) {
					$scope.annee = response.mois;
				});
			// $scope.mois = $scope.annee[0];
		};
	});

angular.module('cahierDeTexteApp')
	.controller('PrincipalEnseignantCtrl', function ($scope, $http, Enseignant) {
		$scope.gridEntries = {
			data: 'data.entries',
			enableCellEdit: false,
			plugins: [new ngGridFlexibleHeightPlugin()],
			rowHeight: 60,
			columnDefs: [
				{ field: 'classe', displayName: 'Classe' },
				{ field: 'cours', displayName: 'Cours', cellTemplate: '<span style="overflow-y:auto" ng-bind-html-unsafe="row.entity.cours"></span>' },
				{ field: 'work', displayName: 'Travail à faire', cellTemplate: '<span style="overflow-y:auto" ng-bind-html-unsafe="row.entity.work"></span>' },
				{ field: 'validated', displayName: 'Validé',
				  cellTemplate: '<div class="ngSelectionCell"><input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" ng-model="row.entity.validated" /></div>'}
			]
		};

		$scope.validateAllEntries = function() {
			$scope.data.entries.map( function( e ) {
				e.validated = true;
			});
		};
		$scope.unvalidateAllEntries = function() {
			$scope.data.entries.map( function( e ) {
				e.validated = false;
			});
		};

		$scope.chart = {};
		$scope.chart.data =  [[ ]];
		$scope.chart.options = {
			seriesDefaults: {
				shadow: false,
				renderer: jQuery.jqplot.PieRenderer,
				rendererOptions: {
					showDataLabels: true,
					sliceMargin: 4,
 					diameter: 128
				}
			},
			legend: { show:false, location: 'e' },
			grid: {
				drawGridLines: false,
				background:"transparent",
				shadow: false
			}
		};
		$scope.chart.update = function() {
			var nbValidatedEntries = $scope.data.entries.reduce(function( x, e ) {
				if ( e.validated ) {
					return x+1;
				} else {
					return x;
				}
			}, 0);
			$scope.chart.data[0].push( [ 'Entrée(s) validée(s)', nbValidatedEntries ] );
			$scope.chart.data[0].push( [ 'Entrée(s) non validée(s)', $scope.data.entries.length - nbValidatedEntries ] );
		};
		
		Enseignant.getEnseignant().success( function( response ) {
			$scope.data = response.data;
			$scope.data.classes = [];
			$scope.data.classesPrincipal = [];

			$scope.$watch($scope.data.entries, $scope.chart.update, true);
			// $scope.chart.update();
			
			$scope.data.entries.map( function( e ) {
				$scope.data.classes.push( e.classe );
				if ( e.principal ) {
					$scope.data.classesPrincipal.push( e.classe );
				}
			});			
		});
	});


