'use strict';

angular.module('cahierDeTexteApp')
  .factory('EnseignantAPI', function Enseignant($resource) {
      return $resource( 'http://localhost:9292/api/v0/etablissement/:etablissement_id/enseignant/:enseignant_id',
			{ etablissement_id: '@etablissement_id',
			  enseignant_id: '@enseignant_id' } );
  });
