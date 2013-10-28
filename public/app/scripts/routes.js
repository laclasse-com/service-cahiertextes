'use strict';

angular.module( 'cahierDeTexteApp' )
    .config( [ '$stateProvider', '$urlRouterProvider', function ( $stateProvider, $urlRouterProvider ) {
	$urlRouterProvider.otherwise('/');

	$stateProvider
	    .state('racine', {
		url: '/',
		templateUrl: 'views/main.html',
		controller: 'MainCtrl'
	    })

	// Principal ///////////////////////////////////////////////////////////
	    .state('principal', {
		url: '/principal',
		templateUrl: 'views/principal/index.html',
		controller: 'PrincipalCtrl'
	    })
	    .state('principal.classes', { //imbriquée sous principal
		parent: 'principal',
		url: '/classes',
		views: {
		    'titre': {
			template: 'Validation des saisies par Classe/Groupe'
		    },
		    'content': {
			templateUrl: 'views/principal/classes.html',
			controller: 'PrincipalClassesCtrl'
		    }
		}
	    })
	    .state('principal.enseignants', { //imbriquée sous principal
		parent: 'principal',
		url: '/enseignants',
		views: {
		    'titre': {
			template: 'Validation des saisies par Enseignants'
		    },
		    'content': {
			templateUrl: 'views/principal/enseignants.html',
			controller: 'PrincipalEnseignantsCtrl'
		    }
		}
	    })
	    .state('principal.enseignant', { //imbriquée sous principal
		parent: 'principal',
		url: '/enseignant/:enseignant_id',
		views: {
		    'titre': {
			template: 'Validation des saisies par Enseignant'
		    },
		    'content': {
			templateUrl: 'views/principal/enseignant.html',
			controller: 'PrincipalEnseignantCtrl'
		    }
		}
	    })

	// Élève ///////////////////////////////////////////////////////////////
	    .state('eleve', {
		url: '/eleve',
		templateUrl: 'views/eleve/index.html',
		controller: 'EleveCtrl'
	    })
	    .state('eleve.emploi_du_temps', {
		parent: 'eleve',
		url: '/emploi_du_temps',
		views: {
		    'content': {
			templateUrl: 'views/eleve/emploi_du_temps.html',
			controller: 'EleveEmploiDuTempsCtrl'
		    }
		}
	    })
	    .state('eleve.devoirs', {
		parent: 'eleve',
		url: '/devoirs',
		views: {
		    'content': {
			templateUrl: 'views/eleve/devoirs.html',
			controller: 'EleveDevoirsCtrl'
		    }
		}
	    })

	// Enseignant //////////////////////////////////////////////////////////
	    .state('enseignant', {
		url: '/enseignant',
		templateUrl: 'views/enseignant.html',
		controller: 'EnseignantCtrl'
	    });
    } ] );
