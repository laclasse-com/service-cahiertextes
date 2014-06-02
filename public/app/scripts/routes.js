'use strict';

angular.module( 'cahierDeTexteApp' )
    .config( [ '$stateProvider', '$urlRouterProvider',
	       function ( $stateProvider, $urlRouterProvider ) {
		   $urlRouterProvider.otherwise('/');

		   // redirections
		   $urlRouterProvider.when( '/principal', '/principal/enseignants' );
		   $urlRouterProvider.when( '/eleve', '/eleve/emploi_du_temps' );

		   $stateProvider
		   // index ///////////////////////////////////////////////////////////////
		       .state('index', {
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'DIR', 'ENS', 'ELV' ] ); } },
			   url: '/',
			   controller: 'IndexCtrl'
		       })
		   // Principal ///////////////////////////////////////////////////////////
		       .state('principal', {
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } },
			   abstract: true,
			   url: '/principal',
			   templateUrl: 'app/views/principal/index.html'
		       })
		       .state('principal.enseignants', {
			   parent: 'principal',
			   url: '/enseignants',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } },
			   views: {
			       'content': {
				   templateUrl: 'app/views/principal/enseignants.html',
				   controller: 'PrincipalEnseignantsCtrl'
			       }
			   }
		       })
		       .state('principal.enseignant', {
			   parent: 'principal',
			   url: '/enseignant/:enseignant_id',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } },
			   views: {
			       'content': {
				   templateUrl: 'app/views/principal/enseignant.html',
				   controller: 'PrincipalEnseignantCtrl'
			       }
			   }
		       })
		       .state('principal.classes', {
			   parent: 'principal',
			   url: '/classes',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } },
			   views: {
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
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ELV', 'PAR' ] ); } },
			   templateUrl: 'app/views/eleve/index.html'
		       })
		       .state('eleve.emploi_du_temps', {
			   parent: 'eleve',
			   url: '/emploi_du_temps',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ELV', 'PAR' ] ); } },
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
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ELV', 'PAR' ] ); } },
			   views: {
			       'content': {
				   templateUrl: 'app/views/eleve/devoirs.html',
				   controller: 'EleveDevoirsCtrl'
			       }
			   }
		       })

		   // Enseignant //////////////////////////////////////////////////////////
		       .state('enseignant', {
			   abstract: true,
			   url: '/enseignant',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ENS' ] ); } },
			   templateUrl: 'app/views/enseignant/index.html',
                           controller: 'EnseignantCtrl'
		       })
		       .state('enseignant.emploi_du_temps', {
                           parent: 'enseignant',
			   url: '/emploi_du_temps',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ENS' ] ); } },
			   views: {
			       'content': {
        			   templateUrl: 'app/views/enseignant/emploi_du_temps.html',
                		   controller: 'EnseignantEmploiDuTempsCtrl'
                               }
                           }
		       })
		       .state('enseignant.stats', {
			   parent: 'enseignant',
			   url: '/stats/:enseignant_id',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ENS' ] ); } },
			   views: {
			       'content': {
				   templateUrl: 'app/views/principal/enseignant.html',
				   controller: 'PrincipalEnseignantCtrl'
			       }
			   }
		       });
	       } ] );
