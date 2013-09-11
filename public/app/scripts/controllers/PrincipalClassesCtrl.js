'use strict';

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
