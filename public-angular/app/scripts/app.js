'use strict';

angular.module('publicAngularApp', ['ui.bootstrap', 'ui.state'])
	.config(function ($stateProvider, $urlRouterProvider) {
		$urlRouterProvider.otherwise("/");
		$stateProvider
			.state('racine', {
				url: "/",
				templateUrl: 'views/main.html',
				controller: 'MainCtrl'
			})
			.state('principal', {
				url: "/principal",
				templateUrl: 'views/principal.html',
				controller: 'PrincipalCtrl'
			})
			.state('principal.classes', { //imbriquée sous principal
				parent: 'principal',
				url: "/classes",
				templateUrl: 'views/principal.classes.html',
				controller: 'PrincipalClassesCtrl'
			})
			.state('principal.enseignants', { //imbriquée sous principal
				parent: 'principal',
				url: "/enseignants",
				templateUrl: 'views/principal.enseignants.html',
				controller: 'PrincipalEnseignantsCtrl'
			})
			.state('principal.enseignant', { //imbriquée sous principal
				parent: 'principal',
				url: "/enseignant",
				templateUrl: 'views/principal.enseignant.html',
				controller: 'PrincipalEnseignantCtrl'
			})
			.state('eleve', {
				url: "/eleve",
				templateUrl: 'views/eleve.html',
				controller: 'EleveCtrl'
			})
			.state('professeur', {
				url: "/professeur",
				templateUrl: 'views/professeur.html',
				controller: 'ProfesseurCtrl'
			});
	});
