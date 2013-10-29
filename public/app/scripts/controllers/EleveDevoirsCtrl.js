'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveDevoirsCtrl',
		[ '$scope', 'Devoirs', 'TypesDeDevoir',
		  function( $scope, Devoirs, TypesDeDevoir ) {
		      $scope.fait = function( id ) {
			  Devoirs.fait({ id: id },
				       function() {
					   _($scope.devoirs).where({ id: id }).fait = true;
				       });
		      };

		      $scope.types_de_devoir = TypesDeDevoir.query();
		      Devoirs.query({ eleve_id: 1 },
				    function( response ) {
					$scope.devoirs = _(response).map( function( devoir ) {
					    devoir.type_devoir = _($scope.types_de_devoir).findWhere({id: devoir.type_devoir_id}).label;
					    return devoir;
					});
				    });
		  } ] );
