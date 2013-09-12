'use strict';

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

  $http({
    method: 'GET',
    url: 'http://localhost:9292/api/v0/etablissement/0134567A/enseignant'
  }).
    success( function( response ) {
               $scope.enseignants = response;
             }).
    error( function (data, status) {
             if (status === 404) {
               $scope.error = 'it does not exist';
             } else {
               $scope.error = 'Error: ' + status + '\nData: ' + data;
             }
           });
  // EmploiDuTemps.getEnseignants().success(
  // 	function( response ) {
  // 	    $scope.enseignants = response;
  // 	    $scope.radar.data.push( $scope.enseignants.map( function( e ) {
  // 		return { axis: e.name, value: e.total };
  // 	    } ) );
  // 	    $scope.radar.data.push( $scope.enseignants.map( function( e ) {
  // 		return { axis: e.name, value: e.stats };
  // 	    } ) );
  // 	});
  // $scope.enseignant = $scope.enseignants[0];

  EmploiDuTemps.getMois().success(
    function( response ) {
      $scope.annee = response.mois;
    });
  $scope.mois = $scope.annee[0];

  console.log($scope.data);
});
