'use strict';

angular.module('publicAngularApp', ['ui.bootstrap', 'ui.state'])
  .config(function ($stateProvider, $urlRouterProvider) {
    $urlRouterProvider.otherwise("/");
    $stateProvider
      .state('/', {
        url: "/",
        templateUrl: 'views/main.html',
        controller: 'MainCtrl'
      })
      .state('/principal', {
        url: "/principal",
        templateUrl: 'views/principal.html',
        controller: 'PrincipalCtrl'
      })
      .state('/eleve', {
        url: "/eleve",
        templateUrl: 'views/eleve.html',
        controller: 'EleveCtrl'
      })
      .state('/professeur', {
        url: "/professeur",
        templateUrl: 'views/professeur.html',
        controller: 'ProfesseurCtrl'
      });
  });
