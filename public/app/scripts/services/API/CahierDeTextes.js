'use strict';

angular.module('cahierDeTexteApp')
    .service('CurrentUser',
	     [ '$http', 'Users',
	       function( $http, Users ) {
		   this.getCurrentUser = _.memoize( function() {
		       var current_user = $http.get( '/api/v0/current_user' ).success(function( response ) {
			   Users.get({ user_id: response.uid }).$promise.then(function( details ) {
			       response.details = details;
			   });
			   return response;
		       });
		       return current_user;
		   });
	       } ] );

angular.module('cahierDeTexteApp')
  .factory('Classes', [ '$resource', function($resource) {
      return $resource( '/api/v0/etablissements/:uai/classes/:id',
			{ uai: '@uai',
			  id: '@id' } );
  } ] );

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

angular.module('cahierDeTexteApp')
    .factory('Devoirs',
	     [ '$resource', function($resource) {
		 return $resource( '/api/v0/devoirs/:id',
				   { id: '@id' },
				   { update: { method: 'PUT' },
				     fait: { method: 'PUT',
					     url: '/api/v0/devoirs/:id/fait' }});
	     } ] );

angular.module('cahierDeTexteApp')
  .factory('EmploisDuTemps',
	   [ '$resource',
	     function($resource) {
		 return $resource( '/api/v0/emplois_du_temps' );
	     } ] );

angular.module('cahierDeTexteApp')
  .factory('Enseignants',
	   [ '$resource',
	     function($resource) {
		 return $resource( '/api/v0/etablissements/:etablissement_id/enseignants/:enseignant_id',
				   { etablissement_id: '@etablissement_id',
				     enseignant_id: '@enseignant_id' } );
	     } ] );

angular.module('cahierDeTexteApp')
  .factory('TypesDeDevoir',
	   [ '$resource',
	     function($resource) {
		 return $resource( '/api/v0/types_de_devoir/:id',
				   { id: '@id' });
	     } ] );



angular.module('cahierDeTexteApp')
    .service('API',
	     [ 'TypesDeDevoir', 'Devoirs',
	       function( TypesDeDevoir, Devoirs ) {
		   this.query_types_de_devoir = _.memoize( function() {
		       return TypesDeDevoir.query().$promise;
		   } );
		   this.query_devoirs = _.memoize( function() {
		       return Devoirs.query().$promise;
		   } );
	       }
	     ] );
