'use strict';

angular.module('cahierDeTexteApp')
  .factory('TypesDeDevoir',
	   [ '$resource',
	     function($resource) {
		 return $resource( '/api/v0/types_de_devoir/:id',
				   { id: '@id' });
	     } ] );
