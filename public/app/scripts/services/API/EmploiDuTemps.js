'use strict';

angular.module('cahierDeTexteApp')
  .factory('EmploiDuTemps',
	   [ '$resource',
	     function($resource) {
		 return $resource( '/api/v0/emploi_du_temps' );
	     } ] );
