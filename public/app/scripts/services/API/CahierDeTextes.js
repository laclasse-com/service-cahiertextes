'use strict';

angular.module('cahierDeTexteApp')
    .service('User',
	     [ '$http', 'APP_PATH',
	       function( $http, APP_PATH ) {
		   this.get_user = _.memoize( function() {
		       return $http.get( APP_PATH + '/api/v0/users/current' )
			   .success( function( response ) {
			       response.profil_actif = response.profils[ 0 ];
			       // Voir quel est le profil
			       response.is = function( profil_id ) {
				   return this.profil_actif['type'] == profil_id;
			       };
			       // Liste des classes liées au profil actif
			       response.profil_actif.classes = _.chain(response.classes)
				   .filter( function( classe ) { return classe.etablissement_code == response.profil_actif.uai; } )
				   .map( function( classe ) {
				       return { id: classe.classe_id,
						libelle: classe.classe_libelle };
				   } )
				   .uniq( function( item ) { return item.id + item.libelle; } )
				   .value();
			       response.profil_actif.matieres = _.chain(response.classes)
				   .filter( function( classe ) { return classe.etablissement_code == response.profil_actif.uai; } )
				   .map( function( classe ) {
				       return { id: classe.matiere_enseignee_id,
						libelle: classe.matiere_libelle };
				   } )
				   .uniq( function( item ) { return item.id + item.libelle; } )
				   .value();
			       return response;
			   } );
		   } );
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('Classes', [ '$resource', 'APP_PATH',
			  function( $resource, APP_PATH ) {
			      return $resource( APP_PATH + '/api/v0/etablissements/:uai/classes/:id',
						{ uai: '@uai',
						  id: '@id' } );
			  } ] );

angular.module('cahierDeTexteApp')
    .factory('Cours',
	     [ '$resource', 'APP_PATH',
	       function( $resource, APP_PATH ) {
		   return $resource( APP_PATH + '/api/v0/cours/:id',
				     { id: '@id' },
				     { update: { method: 'PUT' },
				       valide: { method: 'PUT',
						 url: APP_PATH + '/api/v0/cours/:id/valide' },
				       copie: { method: 'PUT',
						url: APP_PATH + '/api/v0/cours/:id/copie/regroupement/:regroupement_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id',
						params: { id: '@id',
							  regroupement_id: '@regroupement_id',
							  creneau_emploi_du_temps_id: '@creneau_emploi_du_temps_id' } } } );
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('CreneauEmploiDuTemps',
	     [ '$resource', 'APP_PATH',
	       function( $resource, APP_PATH ) {
		   return $resource( APP_PATH + '/api/v0/creneaux_emploi_du_temps/:id',
				     { id: '@id',
				       regroupement_id: '@regroupement_id',
				       jour_de_la_semaine: '@jour_de_la_semaine',
				       heure_debut: '@heure_debut',
				       heure_fin: '@heure_fin',
				       matiere_id: '@matiere_id',
				       semaines_de_presence_regroupement: '@semaines_de_presence_regroupement',
				       semaines_de_presence_enseignant: '@semaines_de_presence_enseignant',
				       semaines_de_presence_salle: '@semaines_de_presence_salle' },
				     { update: { method: 'PUT' },
				       delete: { method: 'DELETE',
						 url: APP_PATH + '/api/v0/creneaux_emploi_du_temps/:id',
						 params: { id: '@id',
							   date_creneau: '@date_creneau' } } } );
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('Devoirs',
	     [ '$resource', 'APP_PATH',
	       function( $resource, APP_PATH ) {
		   return $resource( APP_PATH + '/api/v0/devoirs/:id',
				     { id: '@id' },
				     { update: { method: 'PUT' },
				       fait: { method: 'PUT',
					       url: APP_PATH + '/api/v0/devoirs/:id/fait' }});
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('EmploisDuTemps',
	     [ '$resource', 'APP_PATH',
	       function( $resource, APP_PATH ) {
		   return $resource( APP_PATH + '/api/v0/emplois_du_temps/du/:debut/au/:fin',
				     { debut: '@debut',
				       fin: '@fin',
				       uai: '@uai' } );
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('Enseignants',
	     [ '$resource', 'APP_PATH',
	       function( $resource, APP_PATH ) {
		   return $resource( APP_PATH + '/api/v0/etablissements/:uai/enseignants/:enseignant_id',
				     { uai: '@uai',
				       enseignant_id: '@enseignant_id' } );
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('TypesDeDevoir',
	     [ '$resource', 'APP_PATH',
	       function( $resource, APP_PATH ) {
		   return $resource( APP_PATH + '/api/v0/types_de_devoir/:id',
				     { id: '@id' });
	       } ] );

angular.module('cahierDeTexteApp')
    .factory('PlagesHoraires',
	     [ '$resource', 'APP_PATH',
	       function( $resource, APP_PATH ) {
		   return $resource( APP_PATH + '/api/v0/plages_horaires/:id',
				     { id: '@id' });
	       } ] );



angular.module('cahierDeTexteApp')
    .service('API',
	     [ 'Classes', 'Cours', 'CreneauEmploiDuTemps', 'Devoirs', 'EmploisDuTemps', 'Enseignants', 'TypesDeDevoir', 'PlagesHoraires',
	       function( Classes, Cours, CreneauEmploiDuTemps, Devoirs, EmploisDuTemps, Enseignants, TypesDeDevoir, PlagesHoraires ) {
		   this.query_classes = function( params ) {
			   return Classes.query( params );
		       };

		   this.query_types_de_devoir = _.memoize( function() {
		       return TypesDeDevoir.query();
		   } );
		   this.get_type_de_devoir = _.memoize( function( params ) {
		       return TypesDeDevoir.get( params );
		   } );

		   this.query_emplois_du_temps = function() {
			   return EmploisDuTemps.query();
		       };

		   this.get_creneau_emploi_du_temps = function( params ) {
			   return CreneauEmploiDuTemps.get( params );
		       };

		   this.query_enseignants = function( params ) {
			   return Enseignants.query( params );
		       };
		   this.get_enseignant = function( params ) {
			   return Enseignants.get( params );
		       };

		   this.get_cours = function( params ) {
		       return Cours.get( params );
		   };

		   this.query_devoirs = function( params ) {
		       return Devoirs.query( params );
		       };
		   this.get_devoir = function( params ) {
			   return Devoirs.get( params );
		       };

		   this.query_plages_horaires = function() {
		       return PlagesHoraires.query();
		   };
		   this.get_plage_horaire = function( params ) {
		       return PlagesHoraires.get( params );
		   };
	       }
	     ] );
