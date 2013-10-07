'use strict';

angular.module('cahierDeTexteApp')
    .service('APIAnnuaire',
	     [ '$http',
	       function($http) {
		   this.getMatiere = function( matiere_id ) {
		       return { id: matiere_id,
				libelle_long: 'Matiere_' + matiere_id };
		   };
		   
		   this.getUser = function( user_id ) {
		       user_id = 'VAA60462';
		       return $http.get( 'http://www.dev.laclasse.com/api/app/users/' + user_id );
		   };
		   
		   this.getRegroupement = function( regroupement_id ) {
		       return { id: regroupement_id,
				libelle: 'Regr_' + regroupement_id };
		   };
	       } ] );
