'use strict';

angular.module( 'cahierDeTexteApp' )
    .config( [ '$stateProvider', '$urlRouterProvider', 'APP_PATH',
	       function ( $stateProvider, $urlRouterProvider, APP_PATH ) {
		   $urlRouterProvider.otherwise('/');

		   // redirections
		   $urlRouterProvider.when( '/principal', '/principal/enseignants' );
		   $urlRouterProvider.when( '/eleve', '/eleve/emploi_du_temps' );

		   $stateProvider
		   // 404 /////////////////////////////////////////////////////////////////
		       .state('404', {
			   url: '/404',
			   templateUrl: APP_PATH + '/app/views/common/404.html'
		       })
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
			   templateUrl: APP_PATH + '/app/views/common/tabs.html',
			   controller: 'PrincipalCtrl'
		       })
		       .state('principal.import', {
			   parent: 'principal',
			   url: '/import',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } },
			   views: {
			       'content': {
				   controller: 'ImportCtrl',
				   templateUrl: APP_PATH + '/app/views/principal/import.html'
			       }
			   }
		       })
		       .state('principal.enseignants', {
			   parent: 'principal',
			   url: '/enseignants',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } },
			   views: {
			       'content': {
				   templateUrl: APP_PATH + '/app/views/principal/enseignants.html',
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
				   templateUrl: APP_PATH + '/app/views/common/stats_enseignant.html',
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
				   templateUrl: APP_PATH + '/app/views/principal/classes.html',
				   controller: 'PrincipalClassesCtrl'
			       }
			   }
		       })
		       .state('principal.emploi_du_temps', {
			   parent: 'principal',
			   url: '/emploi_du_temps',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } },
			   views: {
			       'content': {
				   templateUrl: APP_PATH + '/app/views/common/emploi_du_temps.html',
				   controller: 'EmploiDuTempsCtrl'
			       }
			   }
		       })

		   // Vie Scolaire ///////////////////////////////////////////////////////////////
		       .state('vie_scolaire', {
			   abstract: true,
			   url: '/vie_scolaire',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'EVS' ] ); } },
			   controller: 'VieScolaireCtrl',
			   templateUrl: APP_PATH + '/app/views/common/tabs.html'
		       })
		       .state('vie_scolaire.emploi_du_temps', {
			   parent: 'vie_scolaire',
			   url: '/emploi_du_temps',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'EVS' ] ); } },
			   views: {
			       'content': {
				   templateUrl: APP_PATH + '/app/views/common/emploi_du_temps.html',
				   controller: 'EmploiDuTempsCtrl'
			       }
			   }
		       })

		   // Élève ///////////////////////////////////////////////////////////////
		       .state('eleve', {
			   abstract: true,
			   url: '/eleve',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ELV', 'TUT' ] ); } },
			   controller: 'EleveCtrl',
			   templateUrl: APP_PATH + '/app/views/common/tabs.html'
		       })
		       .state('eleve.emploi_du_temps', {
			   parent: 'eleve',
			   url: '/emploi_du_temps',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ELV', 'TUT' ] ); } },
			   views: {
			       'content': {
				   templateUrl: APP_PATH + '/app/views/common/emploi_du_temps.html',
				   controller: 'EmploiDuTempsCtrl'
			       }
			   }
		       })
		       .state('eleve.devoirs', {
			   parent: 'eleve',
			   url: '/devoirs',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ELV', 'TUT' ] ); } },
			   views: {
			       'content': {
				   templateUrl: APP_PATH + '/app/views/eleve/devoirs.html',
				   controller: 'EleveDevoirsCtrl'
			       }
			   }
		       })

		   // Enseignant //////////////////////////////////////////////////////////
		       .state('enseignant', {
			   abstract: true,
			   url: '/enseignant',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ENS' ] ); } },
			   templateUrl: APP_PATH + '/app/views/common/tabs.html',
			   controller: 'EnseignantCtrl'
		       })
		       .state('enseignant.emploi_du_temps', {
			   parent: 'enseignant',
			   url: '/emploi_du_temps',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ENS' ] ); } },
			   views: {
			       'content': {
				   templateUrl: APP_PATH + '/app/views/common/emploi_du_temps.html',
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
				   templateUrl: APP_PATH + '/app/views/common/cahier_de_textes.html',
				   controller: 'CahierDeTextesCtrl'
			       }
			   }
		       })
		       .state('enseignant.stats', {
			   parent: 'enseignant',
			   url: '/stats',
			   resolve: { auth: function( Redirection ) { Redirection.doorman( [ 'ENS' ] ); } },
			   views: {
			       'content': {
				   templateUrl: APP_PATH + '/app/views/common/stats_enseignant.html',
				   controller: 'StatsEnseignantCtrl'
			       }
			   }
		       });
	       } ] );
