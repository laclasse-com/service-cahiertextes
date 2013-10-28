'use strict';

angular.module('cahierDeTexteApp')
    .factory('Devoirs',
	     [ '$resource', function($resource) {
		 return $resource( '/api/v0/devoirs/:id',
				   { id: '@id',
				     eleve_id: '@eleve_id' },
				   { update: { method: 'PUT' },
				     fait: { method: 'PUT',
					     url: '/api/v0/devoirs/:id/fait' }});
	     } ] );
