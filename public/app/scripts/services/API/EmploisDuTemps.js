'use strict';

angular.module('cahierDeTexteApp')
  .factory('EmploisDuTemps',
	   [ '$resource',
	     function($resource) {
		 return $resource( '/api/v0/emplois_du_temps' );
	     } ] );
