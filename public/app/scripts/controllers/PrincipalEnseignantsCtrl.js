'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantsCtrl', [ '$scope', '$rootScope', '$http', 'EmploiDuTemps', function ($scope, $rootScope, $http, EmploiDuTemps) {
	$scope.classe = -1;
	$scope.mois = -1;
	
	$scope.process_data = function(  ) {
	    if ( $scope.raw_data !== undefined ) {
		$scope.enseignants = [];
		$scope.radar = { options: $rootScope.globalRadarChartOptions,
				 data: { labels: [],
					 datasets: [
					     // saisies totales
					     { fillColor : "#aaffaa", pointColor : "#aaffaa",
					       strokeColor : "#88aa88", pointStrokeColor : "#88aa88",
					       data: []
					     },
					     // saisies validées
					     { fillColor : "#00ff00", pointColor : "#00ff00",
					       strokeColor : "#00aa00", pointStrokeColor : "#00aa00",
					       data: []
					     } ] } };

		$scope.classes = _.chain($scope.raw_data)
		    .pluck('classes')
		    .flatten()
		    .pluck('regroupement')
		    .uniq()
		    .value();

		var data = $scope.raw_data;
		
		if ( $scope.classe != -1 ) {
		    data = _.chain(data)
			.map( function( enseignant ) {
			    return { enseignant_id: enseignant.enseignant_id,
				     classes: _(enseignant.classes).reject( function( classe ) {
					 return classe.regroupement != $scope.classe;
				     })
				   };
		        })
			.reject( function( enseignant ) {
			    return enseignant.classes.length === 0;
			})
			.value();
		}

		if ( $scope.mois != -1 ) {
		    data = _(data).map( function( enseignant ) {
			return { enseignant_id: enseignant.enseignant_id,
				 classes: _(enseignant.classes).map( function( classe ) {
				     return { regroupement: classe.regroupement,
					      statistiques: _(classe.statistiques).reject( function( mois ) {
						  return mois.month != $scope.mois;
					      })
					    };
				 })
			       };
		    });
		}

		$scope.enseignants = _(data).map( function( enseignant ) {
		    var stats = _(enseignant.classes).reduce( function( totaux, classe ) {
			var stats = _(classe.statistiques).reduce( function( totaux, mois ) {
			    return { filled: totaux.filled + mois.filled,
				     validated: totaux.validated + mois.validated};
			}, { filled: 0, validated: 0});
			
			return { filled: totaux.filled + stats.filled,
				 validated: totaux.validated + stats.validated};
		    }, { filled: 0, validated: 0});

		    $scope.radar.data.labels.push( enseignant.enseignant_id );
		    $scope.radar.data.datasets[0].data.push( stats.filled );
		    $scope.radar.data.datasets[1].data.push( stats.validated );

		    return { id: enseignant.enseignant_id,
			     name: enseignant.enseignant_id,
			     discipline: '<void>',
			     stats: stats.validated + '/' + stats.filled };
		});
	    }
	};

	// Initialisation
	$scope.gridEnseignants = {
	    data: 'enseignants',
	    enableCellEdit: true,
	    plugins: [new ngGridFlexibleHeightPlugin()],
	    columnDefs: [
		{ field: 'name', displayName: 'Nom', cellTemplate: '<div><a href="#/principal/enseignant/{{row.getProperty(\'id\')}}">{{row.entity[col.field]}}</a></div>' },
		{ field: 'discipline', displayName: 'Discipline' },
		{ field: 'stats', displayName: 'Statistiques' }]
	};
	$scope.annee = [];

	// Récupération et consommation des données
	EmploiDuTemps.getMois()
	    .success(
		function( response ) {
		    $scope.annee = response.mois;
		});

	$scope.enseignant = -1;

	$http({
	    method: 'GET',
	    url: 'http://localhost:9292/api/v0/etablissement/0134567A/enseignant'
	})
	    .success( function( response ) {
		$scope.raw_data = response;
		$scope.process_data(  );
	    })
	    .error( function ( response, status ) {
		if (status === 404) {
		    $scope.error = 'it does not exist';
		} else {
		    $scope.error = 'Error: ' + status + '\nData: ' + response;
		}
	    });
    } ] );
