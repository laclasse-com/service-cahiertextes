'use strict';

angular.module('cahierDeTexteApp')
  .factory('Enseignants',
	   [ '$resource',
	     function($resource) {
		 return $resource( '/api/v0/etablissements/:etablissement_id/enseignant/',
				   { etablissement_id: '@etablissement_id' } );
	     } ] );
