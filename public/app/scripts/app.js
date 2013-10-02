'use strict';

angular.module( 'cahierDeTexteApp',
		[ 'ngResource', 'ui.bootstrap', 'ui.calendar', 'ui.router', 'ui.select2', 'ngGrid', 'angles' ] )
    .config( [ '$stateProvider', '$urlRouterProvider', function ( $stateProvider, $urlRouterProvider ) {
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
    } ] )
    .run( [ '$rootScope', function ($rootScope) {
	// définition des couleurs
	$rootScope.theme = {
	    filled: { base: '#aaffaa',
		      stroke: '#88aa88' },
	    validated: { base: '#00ff00',
			 stroke: '#00aa00' },
	    calendar: { vide: '#a0a0a0',
			saisie: '#aaaaff' }
	};

	// options des calendriers
	$rootScope.globalCalendarOptions = {
	    timeFormat: 'H:mm{ - H:mm}',
	    columnFormat: { month: 'ddd',
			    week: 'ddd d/M',
			    day: 'dddd d MMMM' },
	    titleFormat: { month: 'MMMM yyyy',
			   week: "d MMM[ yyyy]{ '&#8212;' d [ MMM] yyyy}",
			   day: 'dddd d MMMM yyyy' },
	    monthNames: [ 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre' ],
	    monthNamesShort: [ 'Jan.', 'Fév.', 'Mar.', 'Avr.', 'Mai', 'Juin', 'Juil.', 'Août', 'Sep.', 'Oct.', 'Nov.', 'Déc.' ],
	    dayNames: [ 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche' ],
	    dayNamesShort: [ 'Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.' ],
	    buttonText: { prev:     '&lsaquo;',
			  next:     '&rsaquo;',
			  prevYear: '&laquo;',
			  nextYear: '&raquo;',
			  today:    'aujourd\'hui',
			  month:    'mois',
			  week:     'semaine',
			  day:      'jour' }
	};
	// options des graphiques
	$rootScope.globalPieChartOptions = { animationSteps : 24,
					     animationEasing : "easeOutQuart" };
	$rootScope.globalLineChartOptions = { animationSteps : 24 };
	$rootScope.globalRadarChartOptions = { animationSteps : 24 };
    } ] );
