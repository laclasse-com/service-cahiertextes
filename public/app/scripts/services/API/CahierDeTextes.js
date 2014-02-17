'use strict';

// on ne peut pas utiliser $rootScope.APP_VIRTUAL_PATH ici parce que CurrentUser
//   est utilisé dans $rootScope d'où une dépendance circulaire malheureuse :(
angular.module('cahierDeTexteApp')
    .service('CurrentUser',
	     [ '$http',
	       function( $http ) {
		   this.getCurrentUser = _.memoize( function() {
		       return $http.get( '/ct/api/v0/current_user' )
			       .success( function( response ) {
				   return response;
			       } );
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
				     { id: '@id' },
				     { update: { method: 'PUT' },
				       valide: { method: 'PUT',
						 url: $rootScope.APP_VIRTUAL_PATH + '/api/v0/cours/:id/valide' },
				       copie: { method: 'PUT',
						url: $rootScope.APP_VIRTUAL_PATH + '/api/v0/cours/:id/copie/regroupement/:regroupement_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id',
						params: { id: '@id',
							  regroupement_id: '@regroupement_id',
							  creneau_emploi_du_temps_id: '@creneau_emploi_du_temps_id' } } } );
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('CreneauEmploiDuTemps',
	     [ '$resource', '$rootScope',
	       function( $resource, $rootScope ) {
		   return $resource( $rootScope.APP_VIRTUAL_PATH + '/api/v0/creneaux_emploi_du_temps/:id',
				     { id: '@id',
				       regroupement_id: '@regroupement_id',
				       jour_de_la_semaine: '@jour_de_la_semaine',
				       heure_debut: '@heure_debut',
				       heure_fin: '@heure_fin',
				       matiere_id: '@matiere_id' } );
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('Devoirs',
	     [ '$resource', '$rootScope',
	       function( $resource, $rootScope ) {
		   return $resource( $rootScope.APP_VIRTUAL_PATH + '/api/v0/devoirs/:id',
				     { id: '@id' },
				     { update: { method: 'PUT' },
				       fait: { method: 'PUT',
					       url: $rootScope.APP_VIRTUAL_PATH + '/api/v0/devoirs/:id/fait' }});
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
		   return $resource( $rootScope.APP_VIRTUAL_PATH + '/api/v0/etablissements/:uai/enseignants/:enseignant_id',
				     { uai: '@uai',
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
    .factory('PlagesHoraires',
	     [ '$resource', '$rootScope',
	       function( $resource, $rootScope ) {
		   return $resource( $rootScope.APP_VIRTUAL_PATH + '/api/v0/plages_horaires/:id',
				     { id: '@id' });
	       } ] );



angular.module('cahierDeTexteApp')
    .service('API',
	     [ 'Classes', 'Cours', 'CreneauEmploiDuTemps', 'Devoirs', 'EmploisDuTemps', 'Enseignants', 'TypesDeDevoir', 'PlagesHoraires',
	       function( Classes, Cours, CreneauEmploiDuTemps, Devoirs, EmploisDuTemps, Enseignants, TypesDeDevoir, PlagesHoraires ) {
		   this.query_classes = function( params ) {
			   return Classes.query( params ).$promise;
		       };

		   this.query_types_de_devoir = _.memoize( function() {
			   return TypesDeDevoir.query().$promise;
		       } );
		   this.get_type_de_devoir = _.memoize( function( params ) {
			   return TypesDeDevoir.get( params ).$promise;
		       } );

		   this.query_emplois_du_temps = function() {
			   return EmploisDuTemps.query().$promise;
		       };

		   this.get_creneau_emploi_du_temps = function( params ) {
			   return CreneauEmploiDuTemps.get( params ).$promise;
		       };

		   this.query_enseignants = function( params ) {
			   return Enseignants.query( params ).$promise;
		       };
		   this.get_enseignant = function( params ) {
			   return Enseignants.get( params ).$promise;
		       };

		   this.get_cours = // // _.memoize(
		       function( params ) {
			   return Cours.get( params ).$promise;
		       }; //; // );

		   this.query_devoirs = function() {
			   return Devoirs.query().$promise;
		       };
		   this.get_devoir = function( params ) {
			   return Devoirs.get( params ).$promise;
		       };

		   this.query_plages_horaires = function() {
		       return PlagesHoraires.query().$promise;
		   };
		   this.get_plage_horaire = function( params ) {
			   return PlagesHoraires.get( params ).$promise;
		   };
	       }
	     ] );
