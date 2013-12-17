'use strict';

angular.module('cahierDeTexteApp')
    .factory('Devoirs',
	     [ '$resource', function($resource) {
		 return $resource( '/api/v0/devoirs/:id',
				   { id: '@id' },
				   { update: { method: 'PUT' },
				     fait: { method: 'PUT',
					     url: '/api/v0/devoirs/:id/fait' }});
	     } ] );
