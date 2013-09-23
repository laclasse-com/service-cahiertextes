'use strict';

angular.module('cahierDeTexteApp')
  .factory('ClasseAPI', [ '$resource', function Enseignant($resource) {
      return $resource( '/api/v0/etablissement/:uai/classe/:id',
			{ uai: '@uai', id: '@id' });
  } ] );
