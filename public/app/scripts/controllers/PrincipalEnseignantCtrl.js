'use strict';

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
	$scope.chart.options = { };
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
