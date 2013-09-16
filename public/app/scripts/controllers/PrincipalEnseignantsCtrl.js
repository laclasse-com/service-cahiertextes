'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantsCtrl', function ($scope, $rootScope, $http, EmploiDuTemps) {
	$scope.process_data = function( data, mois ) {
	    mois = mois;	//dummy

	    new R( data ).each( function( e ) {
		var stats = { filled: 0,
			      validated: 0};
		stats.validated = e.statistiques.reduce(
		    function(total, monthly_stat) {
			return { validated: total.validated + monthly_stat.validated } ;
		    }, { validated: 0 } ).validated;
		stats.filled = e.statistiques.reduce(
		    function(total, monthly_stat) {
			return { filled: total.filled + monthly_stat.filled } ;
		    }, { filled: 0 } ).filled;
                $scope.enseignants.push( { id: e.enseignant_id,
					   name: e.enseignant_id,
					   discipline: '<void>',
					   stats: stats.validated + '/' + stats.filled
					 });
		$scope.radar.data.labels.push( e.enseignant_id );
		$scope.radar.data.datasets[0].data.push( stats.validated );
		$scope.radar.data.datasets[1].data.push( stats.filled );
            } );
	};
	
	$scope.enseignants = [];
	$scope.annee = [];
	$scope.radar = {};

	$scope.gridEnseignants = {
	    data: 'enseignants',
	    enableCellEdit: true,
	    plugins: [new ngGridFlexibleHeightPlugin()],
	    columnDefs: [
		{ field: 'name', displayName: 'Nom', cellTemplate: '<div><a href="#/principal/enseignant/{{row.getProperty(\'id\')}}">{{row.entity[col.field]}}</a></div>' },
		{ field: 'discipline', displayName: 'Discipline' },
		{ field: 'stats', displayName: 'Statistiques' }]
	};
	$scope.enseignants = [];

	$scope.radar = { options: $rootScope.globalChartOptions,
			 data: { labels: [],
				 datasets: [
				     // 0: saisies validées
				     { fillColor : "#00ff00", pointColor : "#00ff00",
				       strokeColor : "#00aa00", pointStrokeColor : "#00aa00",
				       data: []
				     },
				     // 1: saisies totales
				     { fillColor : "#aaffaa", pointColor : "#aaffaa",
				       strokeColor : "#88aa88", pointStrokeColor : "#88aa88",
				       data: []
				     } ] } };

	EmploiDuTemps.getMois()
	    .success(
		function( response ) {
		    $scope.annee = response.mois;
		});
	$scope.mois = $scope.annee[0];

	$http({
	    method: 'GET',
	    url: 'http://localhost:9292/api/v0/etablissement/0134567A/enseignant'
	})
	    .success( function( response ) {
		$scope.process_data( response, $scope.mois );
	    })
	    .error( function ( response, status ) {
		if (status === 404) {
		    $scope.error = 'it does not exist';
		} else {
		    $scope.error = 'Error: ' + status + '\nData: ' + response;
		}
	    });
    });
