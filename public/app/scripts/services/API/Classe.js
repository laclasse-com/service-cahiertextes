'use strict';

angular.module('cahierDeTexteApp')
  .factory('Classe', [ '$resource', function($resource) {
      return $resource( '/api/v0/etablissement/:uai/classe/:id',
			{ uai: '@uai',
			  id: '@id' } );
  } ] );
