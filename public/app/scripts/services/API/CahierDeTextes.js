'use strict';

angular.module('cahierDeTexteApp')
    .service('CurrentUser',
	     [ '$http', '$rootScope', 'Users',
	       function( $http, $rootScope, Users ) {
		   this.getCurrentUser = _.memoize( function() {
		       var current_user = $http.get( $rootScope.APP_VIRTUAL_PATH + '/api/v0/current_user' ).success(function( response ) {
			   Users.get({ user_id: response.uid }).$promise.then(function( details ) {
			       response.details = details;
			   });
			   return response;
		       });
		       return current_user;
		   });
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('Classes', [ '$resource', '$rootScope',
			  function( $resource, $rootScope ) {
			      return $resource( $rootScope.APP_VIRTUAL_PATH + '/api/v0/etablissements/:uai/classes/:id',
						{ uai: '@uai',
						  id: '@id' } );
			  } ] );

angular.module('cahierDeTexteApp')
    .factory('Cours',
	     [ '$resource', '$rootScope',
	       function( $resource, $rootScope ) {
		   return $resource( $rootScope.APP_VIRTUAL_PATH + '/api/v0/cours/:id',
				     { update: { method: 'PUT' },
				       valide: { method: 'PUT',
						 url: $rootScope.APP_VIRTUAL_PATH + '/api/v0/cours/:id/valide' },
				       copie: { method: 'PUT',
						url: $rootScope.APP_VIRTUAL_PATH + '/api/v0/cours/:id/copie/regroupement/:regroupement_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id',
						params: { id: '@id',
							  regroupement_id: '@regroupement_id',
							  creneau_emploi_du_temps_id: '@creneau_emploi_du_temps_id' } } },
				     { id: '@id' } );
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('CreneauEmploiDuTemps',
	     [ '$resource', '$rootScope',
	       function( $resource, $rootScope ) {
		   return $resource( $rootScope.APP_VIRTUAL_PATH + '/api/v0/creneaux_emploi_du_temps/:id',
				     { update: { method: 'PUT',
						 url: $rootScope.APP_VIRTUAL_PATH + '/api/v0/creneaux_emploi_du_temps/:id/jour_de_la_semaine/:jour_de_la_semaine/debut/:heure_debut/fin/:heure_fin/matiere/:matiere_id/regroupement/:regroupement_id',
						 params: { id: '@id',
							   regroupement_id: '@regroupement_id',
							   jour_de_la_semaine: '@jour_de_la_semaine',
							   heure_debut: '@heure_debut',
							   heure_fin: '@heure_fin',
							   matiere_id: '@matiere_id' } } },
				     { save: { method: 'POST',
					       url: $rootScope.APP_VIRTUAL_PATH + '/api/v0/creneaux_emploi_du_temps/jour_de_la_semaine/:jour_de_la_semaine/debut/:heure_debut/fin/:heure_fin/matiere/:matiere_id/regroupement/:regroupement_id',
					       params: { regroupement_id: '@regroupement_id',
							 jour_de_la_semaine: '@jour_de_la_semaine',
							 heure_debut: '@heure_debut',
							 heure_fin: '@heure_fin',
							 matiere_id: '@matiere_id' }} },
				     { id: '@id' } );
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('Devoirs',
	     [ '$resource', '$rootScope',
	       function( $resource, $rootScope ) {
		   return $resource( $rootScope.APP_VIRTUAL_PATH + '/api/v0/devoirs/:id',
				     { update: { method: 'PUT' },
				       fait: { method: 'PUT',
					       url: $rootScope.APP_VIRTUAL_PATH + '/api/v0/devoirs/:id/fait' }},
				     { id: '@id' });
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('EmploisDuTemps',
	     [ '$resource', '$rootScope',
	       function( $resource, $rootScope ) {
		   return $resource( $rootScope.APP_VIRTUAL_PATH + '/api/v0/emplois_du_temps' );
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('Enseignants',
	     [ '$resource', '$rootScope',
	       function( $resource, $rootScope ) {
		   return $resource( $rootScope.APP_VIRTUAL_PATH + '/api/v0/etablissements/:etablissement_id/enseignants/:enseignant_id',
				     { etablissement_id: '@etablissement_id',
				       enseignant_id: '@enseignant_id' } );
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('TypesDeDevoir',
	     [ '$resource', '$rootScope',
	       function( $resource, $rootScope ) {
		   return $resource( $rootScope.APP_VIRTUAL_PATH + '/api/v0/types_de_devoir/:id',
				     { id: '@id' });
	       } ] );



angular.module('cahierDeTexteApp')
    .service('API',
	     [ 'Classes', 'Cours', 'CreneauEmploiDuTemps', 'Devoirs', 'EmploisDuTemps', 'Enseignants', 'TypesDeDevoir',
	       function( Classes, Cours, CreneauEmploiDuTemps, Devoirs, EmploisDuTemps, Enseignants, TypesDeDevoir ) {
		   this.query_classes = _.memoize( function( uai ) {
		       return Classes.query({ uai: uai }).$promise;
		   } );

		   this.query_types_de_devoir = _.memoize( function() {
		       return TypesDeDevoir.query().$promise;
		   } );
		   this.get_type_de_devoir = _.memoize( function( id ) {
		       return TypesDeDevoir.get({ id: id }).$promise;
		   } );

		   this.query_emplois_du_temps = _.memoize( function() {
		       return EmploisDuTemps.query().$promise;
		   } );

		   this.query_enseignants = _.memoize( function( uai ) {
		       return Enseignants.query({ etablissement_id: uai }).$promise;
		   } );
		   this.get_enseignant = _.memoize( function( id, uai ) {
		       return Enseignants.get({ enseignant_id: id, etablissement_id: uai }).$promise;
		   } );

		   this.get_cours = _.memoize( function( id ) {
		       return Cours.get({ id: id }).$promise;
		   } );

		   this.query_devoirs = _.memoize( function() {
		       return Devoirs.query().$promise;
		   } );
		   this.get_devoir = _.memoize( function( id ) {
		       return Devoirs.get({ id: id }).$promise;
		   } );
	       }
	     ] );
