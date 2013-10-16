'use strict';

angular.module('cahierDeTexteApp')
  .factory('Enseignants',
	   [ '$resource',
	     function($resource) {
		 return $resource( '/api/v0/etablissements/:etablissement_id/enseignants/:enseignant_id',
				   { etablissement_id: '@etablissement_id',
				     enseignant_id: '@enseignant_id' } );
	     } ] );
