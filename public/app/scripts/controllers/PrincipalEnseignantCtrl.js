'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantCtrl', function ($scope, $http, $stateParams) {
	$scope.process_data = function(  ) {
	    $scope.saisies = [];
	    if ( typeof $scope.raw_data !== 'undefined' ) {
		$scope.raw_data.saisies.forEach( function( m ) {
		    m.forEach( function ( e ) {
			console.log( e.cours );
			$scope.saisies.push( { classe: e.classe_id,
					       cours: e.cours,
					       devoir: e.devoir,
					       valide: e.valide } );
		    } );
		} );

		$scope.classes = _.uniq( $scope.saisies.map( function( e ) {
		    return e.classe;
		} ) );
	    }
	};
	$scope.enseignant_id = $stateParams.enseignant_id;
	
	// Tableau
	$scope.gridEntries = {
	    data: 'saisies',
	    enableCellEdit: false,
	    plugins: [new ngGridFlexibleHeightPlugin()],
	    rowHeight: 60,
	    columnDefs: [
		{ field: 'classe', displayName: 'Classe' },
		{ field: 'cours', displayName: 'Cours', cellTemplate: '<span style="overflow-y:auto" ng-bind-html-unsafe="row.entity.cours">{{row.entity.cours}}</span>' },
		{ field: 'devoir', displayName: 'Travail à faire', cellTemplate: '<span style="overflow-y:auto" ng-bind-html-unsafe="row.entity.devoir">{{row.entity.devoir}}</span>' },
		{ field: 'validated', displayName: 'Validé',
		  cellTemplate: '<div class="ngSelectionCell"><input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" ng-model="row.entity.valide" /></div>'}
	    ]
	};

	$scope.validateAllEntries = function() {
	    $scope.saisies.forEach( function( e ) {
		e.valide = true;
	    });
	};
	$scope.unvalidateAllEntries = function() {
	    $scope.saisies.forEach( function( e ) {
		e.valide = false;
	    });
	};

	// Récupération de données
	$http({
	    method: 'GET',
	    url: 'http://localhost:9292/api/v0/etablissement/0134567A/enseignant/' + $scope.enseignant_id
	})
	    .success( function( response ) {
		$scope.raw_data = response;
		$scope.process_data(  );
	    });
    });
