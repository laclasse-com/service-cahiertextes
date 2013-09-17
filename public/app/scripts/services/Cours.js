'use strict';

angular.module('cahierDeTexteApp')
  .factory('CoursAPI', [ '$resource', function Enseignant($resource) {
      return $resource( '/api/v0/cours/:id',
			{ id: '@id' },
			{ valide: { method: 'PUT',
				    url: '/api/v0/cours/:id/valide' }});
  } ] );
