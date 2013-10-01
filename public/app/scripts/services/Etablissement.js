'use strict';

angular.module('cahierDeTexteApp')
	.service('Etablissement', [ '$http', function($http) {
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
	} ] );
