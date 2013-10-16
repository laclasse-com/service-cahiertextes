'use strict';

angular.module('cahierDeTexteApp')
  .factory('Enseignant',
	   [ '$resource',
	     function($resource) {
		 return $resource( '/api/v0/etablissements/:etablissement_id/enseignant/:enseignant_id',
				   { etablissement_id: '@etablissement_id',
				     enseignant_id: '@enseignant_id' } );
	     } ] );
