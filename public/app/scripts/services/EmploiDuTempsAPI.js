'use strict';

angular.module('cahierDeTexteApp')
  .factory('EmploiDuTempsAPI', [ '$resource', function($resource) {
      return $resource( '/api/v0/emploi_du_temps' );// ,
			// { id: '@id' });
  } ] );
