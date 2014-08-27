'use strict';

angular.module( 'cahierDeTexteApp' )
    .config( [ '$stateProvider', '$urlRouterProvider',
	       function ( $stateProvider, $urlRouterProvider ) {
		   $urlRouterProvider.otherwise('/');

		   // redirections
		   $urlRouterProvider.when( '/principal', '/principal/enseignants' );
		   $urlRouterProvider.when( '/eleve', '/eleve/emploi_du_temps' );

		   $stateProvider
		   // 404 /////////////////////////////////////////////////////////////////
		       .state('404', {
			   url: '/404',
			   templateUrl: 'app/views/common/404.html'
		       })
		   // index ///////////////////////////////////////////////////////////////
		       .state('index', {
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'DIR', 'ENS', 'ELV' ] ); } },
			   url: '/',
			   controller: 'IndexCtrl'
		       })
		   // import //////////////////////////////////////////////////////////////
		       .state('import', {
			       //resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } },
			   url: '/import',
			   controller: 'ImportCtrl',
			   templateUrl: 'app/views/import.html'
		       })
		   // Principal ///////////////////////////////////////////////////////////
		       .state('principal', {
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } },
			   abstract: true,
			   url: '/principal',
			   templateUrl: 'app/views/common/tabs.html',
			   controller: 'PrincipalCtrl'
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
			   url: '/enseignants/:enseignant_id',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } },
			   views: {
			       'content': {
				   templateUrl: 'app/views/common/stats_enseignant.html',
				   controller: 'StatsEnseignantCtrl'
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
			   controller: 'EleveCtrl',
			   templateUrl: 'app/views/common/tabs.html'
		       })
		       .state('eleve.emploi_du_temps', {
			   parent: 'eleve',
			   url: '/emploi_du_temps',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ELV', 'PAR' ] ); } },
			   views: {
			       'content': {
				   templateUrl: 'app/views/eleve/emploi_du_temps.html',
				   controller: 'EmploiDuTempsCtrl'
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
			   templateUrl: 'app/views/common/tabs.html',
			   controller: 'EnseignantCtrl'
		       })
		       .state('enseignant.emploi_du_temps', {
			   parent: 'enseignant',
			   url: '/emploi_du_temps',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ENS' ] ); } },
			   views: {
			       'content': {
				   templateUrl: 'app/views/enseignant/emploi_du_temps.html',
				   controller: 'EmploiDuTempsCtrl'
			       }
			   }
		       })
		       .state('enseignant.cahier_de_textes', {
			   parent: 'enseignant',
			   url: '/cahier_de_textes',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ENS' ] ); } },
			   views: {
			       'content': {
				   templateUrl: 'app/views/enseignant/liste.html',
				   controller: 'ListeCahierDeTextesCtrl'
			       }
			   }
		       })
		       .state('enseignant.stats', {
			   parent: 'enseignant',
			   url: '/stats',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ENS' ] ); } },
			   views: {
			       'content': {
				   templateUrl: 'app/views/common/stats_enseignant.html',
				   controller: 'StatsEnseignantCtrl'
			       }
			   }
		       });
	       } ] );
