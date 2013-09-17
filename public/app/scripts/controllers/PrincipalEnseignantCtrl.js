'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantCtrl', [ '$scope', '$stateParams', 'EnseignantAPI', function ($scope, $stateParams, EnseignantAPI) {
	$scope.enseignant_id = $stateParams.enseignant_id;

	$scope.process_data = function(  ) {
	    $scope.saisies = [];
	    if ( typeof $scope.raw_data !== 'undefined' ) {
		_.each( $scope.raw_data.saisies, function( m ) {
		    _.each( m, function ( e ) {
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
	    _.each( $scope.saisies, function( e ) {
		e.valide = true;
	    });
	};
	$scope.unvalidateAllEntries = function() {
	    _.each( $scope.saisies, function( e ) {
		e.valide = false;
	    });
	};

	// Récupération et consommation des données
	EnseignantAPI.get( { enseignant_id: $scope.enseignant_id,
			     etablissement_id: '0134567A' },
			   function( response ) {
			       $scope.raw_data = response;
			       $scope.process_data();
			   } );
    } ] );
