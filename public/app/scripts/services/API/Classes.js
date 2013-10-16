'use strict';

angular.module('cahierDeTexteApp')
  .factory('Classes', [ '$resource', function($resource) {
      return $resource( '/api/v0/etablissements/:uai/classes/:id',
			{ uai: '@uai',
			  id: '@id' } );
  } ] );
