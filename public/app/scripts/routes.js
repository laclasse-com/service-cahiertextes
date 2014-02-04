'use strict';

angular.module( 'cahierDeTexteApp' )
    .config( [ '$stateProvider', '$urlRouterProvider',
	       function ( $stateProvider, $urlRouterProvider ) {
		   $urlRouterProvider.otherwise('/');

		   // redirections
		   $urlRouterProvider.when( '/principal', '/principal/enseignants' );
		   $urlRouterProvider.when( '/eleve', '/eleve/emploi_du_temps' );

		   $stateProvider
		   // Principal ///////////////////////////////////////////////////////////
		       .state('principal', {
			   data: { auth: [ 'DIR' ] },
			   abstract: true,
			   url: '/principal',
			   templateUrl: 'app/views/principal/index.html'
		       })
		       .state('principal.enseignants', { //imbriquée sous principal
			   parent: 'principal',
			   url: '/enseignants',
			   data: { auth: [ 'DIR' ] },
			   views: {
			       'titre': {
				   template: 'Validation des saisies par Enseignants'
			       },
			       'content': {
				   templateUrl: 'app/views/principal/enseignants.html',
				   controller: 'PrincipalEnseignantsCtrl'
			       }
			   }
		       })
		       .state('principal.enseignant', { //imbriquée sous principal
			   parent: 'principal',
			   url: '/enseignant/:enseignant_id',
			   data: { auth: [ 'DIR' ] },
			   views: {
			       'titre': {
				   template: 'Validation des saisies par Enseignant'
			       },
			       'content': {
				   templateUrl: 'app/views/principal/enseignant.html',
				   controller: 'PrincipalEnseignantCtrl'
			       }
			   }
		       })
		       .state('principal.classes', { //imbriquée sous principal
			   parent: 'principal',
			   url: '/classes',
			   data: { auth: [ 'DIR' ] },
			   views: {
			       'titre': {
				   template: 'Validation des saisies par Classe/Groupe'
			       },
			       'content': {
				   templateUrl: 'app/views/principal/classes.html',
				   controller: 'PrincipalClassesCtrl'
			       }
			   }
		       })

		   // Élève ///////////////////////////////////////////////////////////////
		       .state('eleve', {
			   abstract: true,
			   url: '/eleve',
			   data: { auth: [ 'ELV', 'PAR' ] },
			   templateUrl: 'app/views/eleve/index.html'
		       })
		       .state('eleve.emploi_du_temps', {
			   parent: 'eleve',
			   url: '/emploi_du_temps',
			   data: { auth: [ 'ELV', 'PAR' ] },
			   views: {
			       'content': {
				   templateUrl: 'app/views/eleve/emploi_du_temps.html',
				   controller: 'EleveEmploiDuTempsCtrl'
			       }
			   }
		       })
		       .state('eleve.devoirs', {
			   parent: 'eleve',
			   url: '/devoirs',
			   data: { auth: [ 'ELV', 'PAR' ] },
			   views: {
			       'content': {
				   templateUrl: 'app/views/eleve/devoirs.html',
				   controller: 'EleveDevoirsCtrl'
			       }
			   }
		       })

		   // Enseignant //////////////////////////////////////////////////////////
		       .state('enseignant', {
			   url: '/enseignant',
			   data: { auth: [ 'ENS' ] },
			   templateUrl: 'app/views/enseignant.html',
			   controller: 'EnseignantCtrl'
		       });
	       } ] );
