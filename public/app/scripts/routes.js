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
			   data: { auth: [ 'DIR', 'ENS', 'ELV' ] },
			   url: '/',
			   controller: 'IndexCtrl'
		       })
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
	       } ] )
    .run( [ '$rootScope', '$location', 'User',
	    function ( $rootScope, $location, User ) {
		$rootScope.$on( '$stateChangeStart',
				function( event, toState, toParams, fromState, fromParams ) {
				    User.get_user().then( function( response ) {
					var current_user = response.data;
					var allowed = _(current_user.profils).reduce(
					    function( autorise, profil ) {
						return autorise && _(toState.data.auth).contains( profil.type );
					    },
					    true );

					if ( ! allowed ) {
					    event.preventDefault();

					    var profil_etab = _(current_user.profils).find( function( p ) {
						return p.uai == current_user.etablissement_actif;
					    } );

					    switch ( profil_etab.type ) {
					    case 'DIR':
						$location.url( '/principal' );
						break;
					    case 'ENS':
						$location.url( '/enseignant' );
						break;
					    case 'ELV':
						$location.url( '/eleve' );
						break;
					    }
					    $location.replace();
					}
				    } );
				} );
	    } ] );
