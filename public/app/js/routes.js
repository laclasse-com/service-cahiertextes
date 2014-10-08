'use strict';

cahierDeTexteApp
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
			   templateUrl: 'views/404.html'
		       })
		   // index ///////////////////////////////////////////////////////////////
		       .state('index', {
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'DIR', 'ENS', 'ELV', 'TUT', 'EVS' ] ); } ] },
			   url: '/',
			   controller: 'IndexCtrl'
		       })
		   // Principal ///////////////////////////////////////////////////////////
		       .state('principal', {
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } ],
				      current_user: [ 'User', function( User ) { return User.get_user().then( function( response ) { return response.data; } ); } ] },
			   abstract: true,
			   url: '/principal',
			   templateUrl: 'views/index.html',
			   controller: 'PrincipalCtrl'
		       })
		       .state('principal.import', {
			   parent: 'principal',
			   url: '/import',
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } ] },
			   views: {
			       'content': {
				   controller: 'ImportCtrl',
				   templateUrl: 'views/import.html'
			       }
			   }
		       })
		       .state('principal.enseignants', {
			   parent: 'principal',
			   url: '/enseignants',
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } ] },
			   views: {
			       'content': {
				   templateUrl: 'views/enseignants.html',
				   controller: 'PrincipalEnseignantsCtrl'
			       }
			   }
		       })
		       .state('principal.enseignant', {
			   parent: 'principal',
			   url: '/enseignants/:enseignant_id',
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } ] },
			   views: {
			       'content': {
				   templateUrl: 'views/stats_enseignant.html',
				   controller: 'StatsEnseignantCtrl'
			       }
			   }
		       })
		       .state('principal.classes', {
			   parent: 'principal',
			   url: '/classes',
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } ] },
			   views: {
			       'content': {
				   templateUrl: 'views/classes.html',
				   controller: 'PrincipalClassesCtrl'
			       }
			   }
		       })
		       .state('principal.emploi_du_temps', {
			   parent: 'principal',
			   url: '/emploi_du_temps',
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } ] },
			   views: {
			       'content': {
				   templateUrl: 'views/emploi_du_temps.html',
				   controller: 'EmploiDuTempsCtrl'
			       }
			   }
		       })

		   // Vie Scolaire ///////////////////////////////////////////////////////////////
		       .state('vie_scolaire', {
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'EVS' ] ); } ],
				      current_user: [ 'User', function( User ) { return User.get_user().then( function( response ) { return response.data; } ); } ] },
			   abstract: true,
			   url: '/vie_scolaire',
			   controller: 'VieScolaireCtrl',
			   templateUrl: 'views/index.html'
		       })
		       .state('vie_scolaire.emploi_du_temps', {
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'EVS' ] ); } ] },
			   parent: 'vie_scolaire',
			   url: '/emploi_du_temps',
			   views: {
			       'content': {
				   templateUrl: 'views/emploi_du_temps.html',
				   controller: 'EmploiDuTempsCtrl'
			       }
			   }
		       })

		   // Élève ///////////////////////////////////////////////////////////////
		       .state('eleve', {
			   abstract: true,
			   url: '/eleve',
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'ELV', 'TUT' ] ); } ],
				      current_user: [ 'User', function( User ) { return User.get_user().then( function( response ) { return response.data; } ); } ] },
			   controller: 'EleveCtrl',
			   templateUrl: 'views/index.html'
		       })
		       .state('eleve.emploi_du_temps', {
			   parent: 'eleve',
			   url: '/emploi_du_temps',
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'ELV', 'TUT' ] ); } ] },
			   views: {
			       'content': {
				   templateUrl: 'views/emploi_du_temps.html',
				   controller: 'EmploiDuTempsCtrl'
			       }
			   }
		       })
		       .state('eleve.devoirs', {
			   parent: 'eleve',
			   url: '/devoirs',
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'ELV', 'TUT' ] ); } ] },
			   views: {
			       'content': {
				   templateUrl: 'views/devoirs.html',
				   controller: 'EleveDevoirsCtrl'
			       }
			   }
		       })
		       .state('eleve.devoirs.popup', {
			   parent: 'eleve.devoirs',
			   url: '/popup/:titre/:cours_id/:devoirs_ids',
			   onEnter: [ '$stateParams', '$state', 'PopupsCreneau',
				      function( $stateParams, $state, PopupsCreneau ) {
					  var dummy = false;
					  PopupsCreneau.display( $stateParams.titre,
								 { id: parseInt( $stateParams.cours_id ) },
								 JSON.parse( $stateParams.devoirs_ids ).map( function( id ) { return { id: id }; } ),
								 function() { return $state.go( 'eleve.devoirs', $state.params, { reload: true, inherit: true, notify: true } ); },
								 dummy );
				      }]
		       })

		   // Enseignant //////////////////////////////////////////////////////////
		       .state('enseignant', {
			   abstract: true,
			   url: '/enseignant',
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'ENS' ] ); } ],
				      current_user: [ 'User', function( User ) { return User.get_user().then( function( response ) { return response.data; } ); } ] },
			   templateUrl: 'views/index.html',
			   controller: 'EnseignantCtrl'
		       })
		       .state('enseignant.emploi_du_temps', {
			   parent: 'enseignant',
			   url: '/emploi_du_temps',
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'ENS' ] ); } ] },
			   views: {
			       'content': {
				   templateUrl: 'views/emploi_du_temps.html',
				   controller: 'EmploiDuTempsCtrl'
			       }
			   }
		       })
		       .state('enseignant.cahier_de_textes', {
			   parent: 'enseignant',
			   url: '/cahier_de_textes',
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'ENS' ] ); } ] },
			   views: {
			       'content': {
				   templateUrl: 'views/cahier_de_textes.html',
				   controller: 'CahierDeTextesCtrl'
			       }
			   }
		       })
		       .state('enseignant.stats', {
			   parent: 'enseignant',
			   url: '/stats',
			   resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'ENS' ] ); } ] },
			   views: {
			       'content': {
				   templateUrl: 'views/stats_enseignant.html',
				   controller: 'StatsEnseignantCtrl'
			       }
			   }
		       });
	       } ] );
