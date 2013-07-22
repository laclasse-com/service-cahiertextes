'use strict';

angular.module('publicAngularApp', ['ui.bootstrap'])
  .config(function ($routeProvider) {
    $routeProvider
      .when('/', {
angular.module('publicAngularApp', ['ui.bootstrap', 'ui.state'])
        templateUrl: 'views/main.html',
        controller: 'MainCtrl'
      })
      .when('/principal', {
        templateUrl: 'views/principal.html',
        controller: 'PrincipalCtrl'
      })
      .when('/eleve', {
        templateUrl: 'views/eleve.html',
        controller: 'EleveCtrl'
      })
      .when('/professeur', {
        templateUrl: 'views/professeur.html',
        controller: 'ProfesseurCtrl'
      })
      .otherwise({
        redirectTo: '/'
      });
  });
