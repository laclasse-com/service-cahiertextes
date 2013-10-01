'use strict';

angular.module('cahierDeTexteApp')
  .factory('APIEmploiDuTemps',
	   [ '$resource',
	     function($resource) {
		 return $resource( '/api/v0/emploi_du_temps' );
	     } ] );
