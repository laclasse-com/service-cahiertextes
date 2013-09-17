'use strict';

angular.module('cahierDeTexteApp')
  .factory('EnseignantAPI', [ '$resource', function Enseignant($resource) {
      return $resource( '/api/v0/etablissement/:etablissement_id/enseignant/:enseignant_id',
			{ etablissement_id: '@etablissement_id',
			  enseignant_id: '@enseignant_id' } );
  } ] );
