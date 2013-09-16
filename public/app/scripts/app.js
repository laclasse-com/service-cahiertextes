'use strict';

angular.module( 'cahierDeTexteApp',
		[ 'ui.bootstrap', 'ui.calendar', 'ui.router', 'ui.select2', 'ngGrid', 'angles' ] )
    .config( function ( $stateProvider, $urlRouterProvider ) {
	$urlRouterProvider.otherwise('/');

	$stateProvider
	    .state('racine', {
		url: '/',
		templateUrl: 'views/main.html',
		controller: 'MainCtrl'
	    })
	    .state('principal', {
		url: '/principal',
		templateUrl: 'views/principal.html',
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
			templateUrl: 'views/principal.classes.html',
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
			templateUrl: 'views/principal.enseignants.html',
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
			templateUrl: 'views/principal.enseignant.html',
			controller: 'PrincipalEnseignantCtrl'
		    }
		}
	    })
	    .state('eleve', {
		url: '/eleve',
		templateUrl: 'views/eleve.html',
		controller: 'EleveCtrl'
	    })
	    .state('enseignant', {
		url: '/enseignant',
		templateUrl: 'views/enseignant.html',
		controller: 'EnseignantCtrl'
	    });
    })
    .run(function ($rootScope) {
	$rootScope.globalChartOptions = { segmentShowStroke : true,
					  segmentStrokeColor : "#fff",
					  segmentStrokeWidth : 24,
					  percentageInnerCutout : 50,
					  animation : true,
					  animationSteps : 100,
					  animationEasing : "easeOutQuart",
					  animateRotate : true,
					  animateScale : false,
					  onAnimationComplete : null }; //global variable
    });
