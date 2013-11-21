'use strict';

angular.module('cahierDeTexteApp')
    .factory('Cours',
	     [ '$resource', function($resource) {
		 return $resource( '/api/v0/cours/:id',
				   { id: '@id',
				     regroupement_id: '@regroupement_id',
				     creneau_emploi_du_temps_id: '@creneau_emploi_du_temps_id' },
				   { update: { method: 'PUT' },
				     valide: { method: 'PUT',
					       url: '/api/v0/cours/:id/valide' },
				     copie: { method: 'PUT',
					      url: '/api/v0/cours/:id/copie/regroupement/:regroupement_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id' } } );
	     } ] );
