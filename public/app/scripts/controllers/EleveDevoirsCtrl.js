'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveDevoirsCtrl',
		[ '$scope', 'Devoirs',
		  function ( $scope, Devoirs ) {
		      $scope.fait = function( id ) {
			  Devoirs.fait({ id: id },
				       function() {
					   $scope.devoirs.where({ id: id }).fait = true;
				       });
		      };

		      $scope.devoirs = Devoirs.query({ eleve_id: 1 });
		  } ] );
