'use strict';

angular.module('cahierDeTexteApp')
    .factory('CreneauEmploiDuTemps',
	     [ '$resource', function($resource) {
		 return $resource( '/api/v0/creneau_emploi_du_temps/:id',
				   { id: '@id',
				     regroupement_id: '@regroupement_id',
				     jour_de_la_semaine: '@jour_de_la_semaine',
				     heure_debut: '@heure_debut',
				     heure_fin: '@heure_fin',
				     matiere_id: '@matiere_id' },
				   { update: { method: 'PUT' } } );
	     } ] );
