'use strict';

angular.module('cahierDeTexteApp')
  .factory('EnseignantsAPI',
	   [ '$resource',
	     function($resource) {
		 return $resource( '/api/v0/etablissement/:etablissement_id/enseignant/',
				   { etablissement_id: '@etablissement_id' } );
	     } ] );
