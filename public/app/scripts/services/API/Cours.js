'use strict';

angular.module('cahierDeTexteApp')
    .factory('Cours',
	     [ '$resource', function($resource) {
		 return $resource( '/api/v0/cours/:id',
				   { id: '@id' },
				   { update: { method: 'PUT' },
				     valide: { method: 'PUT',
					       url: '/api/v0/cours/:id/valide' } } );
	     } ] );
