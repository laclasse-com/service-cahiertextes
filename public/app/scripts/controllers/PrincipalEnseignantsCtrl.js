'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantsCtrl', function ($scope, $http, EmploiDuTemps) {
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

	$http({
	    method: 'GET',
	    url: 'http://localhost:9292/api/v0/etablissement/0134567A/enseignant'
	}).
	    success( function( response ) {
		$scope.data = response;
		$scope.enseignants = $scope.data.map( function( e ) {
                    return { id: e.enseignant_id,
                             name: e.enseignant_id,
                             discipline: '<void>',
                             stats: e.statistiques.reduce( function(total, monthly_stat) {
                                 return { validated: total.validated + monthly_stat.validated } ;
                             }, { validated: 0 } ).validated + '/' + e.statistiques.reduce(
				 function(total, monthly_stat) {
                                     return { filled: total.filled + monthly_stat.filled } ;
				 }, { filled: 0 } ).filled
			   };
                } );

		$scope.radar.options =  {
		    segmentShowStroke : true,  //Boolean - Whether we should show a stroke on each segment
		    segmentStrokeColor : "#fff",  //String - The colour of each segment stroke
		    segmentStrokeWidth : 24,  //Number - The width of each segment stroke
		    percentageInnerCutout : 50,  //The percentage of the chart that we cut out of the middle.
		    animation : true,  //Boolean - Whether we should animate the chart
		    animationSteps : 100,  //Number - Amount of animation steps
		    animationEasing : "easeOutBounce",  //String - Animation easing effect
		    animateRotate : true,  //Boolean - Whether we animate the rotation of the Doughnut
		    animateScale : false,  //Boolean - Whether we animate scaling the Doughnut from the centre
		    onAnimationComplete : null  //Function - Will fire on animation completion.
		};
		$scope.radar.data = {
		    labels: $scope.data.map( function( e ) { return e.enseignant_id; } ),
		    datasets: [ { fillColor : "#00ff00",
				  strokeColor : "#00aa00",
				  pointColor : "#00ff00",
				  pointStrokeColor : "#00aa00",
				  data: $scope.data.map( function( e ) {
				      return e.statistiques.reduce( function(total, monthly_stat) {
					  return { validated: total.validated + monthly_stat.validated } ;
				      }, { validated: 0 } ).validated; } )
				},
				{ fillColor : "#aaffaa",
				  strokeColor : "#88aa88",
				  pointColor : "#aaffaa",
				  pointStrokeColor : "#88aa88",
				  data: $scope.data.map( function( e ) {
				      return e.statistiques.reduce( function(total, monthly_stat) {
					  return { filled: total.filled + monthly_stat.filled } ;
				      }, { filled: 0 } ).filled; } )
				} ]
		};
						   }).
	    error( function (data, status) {
		if (status === 404) {
		    $scope.error = 'it does not exist';
		} else {
		    $scope.error = 'Error: ' + status + '\nData: ' + data;
		}
	    });

	EmploiDuTemps.getMois().success(
	    function( response ) {
		$scope.annee = response.mois;
	    });
	$scope.mois = $scope.annee[0];
    });
