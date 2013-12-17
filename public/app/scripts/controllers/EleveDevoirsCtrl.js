'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveDevoirsCtrl',
		[ '$scope', 'Devoirs', 'TypesDeDevoir',
		  function( $scope, Devoirs, TypesDeDevoir ) {
		      $scope.affiche_faits = false;
		      $scope.fait = function( id ) {
			  Devoirs.fait({ id: id }).$promise
			      .then( function() {
				  _($scope.devoirs).findWhere({ id: id }).fait = true;
			      });
		      };

		      $scope.types_de_devoir = TypesDeDevoir.query();
		      $scope.filtre = function() {
			  if ( ! $scope.affiche_faits ) {
			      $scope.devoirs = _($scope.all_devoirs).reject(function( devoir ) {
				  return devoir.fait;
			      });
			  } else {
			      $scope.devoirs = $scope.all_devoirs;
			  }
		      };
		      Devoirs.query(function( response ) {
					$scope.all_devoirs = _(response).map( function( devoir ) {
					    devoir.type_devoir = _($scope.types_de_devoir)
						.findWhere({id: devoir.type_devoir_id}).label;
					    return devoir;
					});
					$scope.filtre();
				    });
		  } ] );
