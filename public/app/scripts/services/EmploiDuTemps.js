'use strict';

angular.module('publicAngularApp')
  .service('EmploiDuTemps', function EmploiDuTemps($http) {
			this.getMois = function() {
					return $http.get( 'mocks/mois.json' );
			};
	  
			this.getClasses = function() {
					return $http.get( 'mocks/classes.json' );
			};
	  
			this.getMatieres = function() {
					return $http.get( 'mocks/matieres.json' );
			};
	  
			this.getEnseignants = function() {
					return $http.get( 'mocks/enseignants.json' );
			};
	  
  });
