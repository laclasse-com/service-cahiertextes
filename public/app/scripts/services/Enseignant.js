'use strict';

angular.module('cahierDeTexteApp')
  .service('Enseignant', function Enseignant($http) {
	  this.getEnseignant = function() {
		  return $http.get( 'mocks/enseignant.json' );
	  };
  });
