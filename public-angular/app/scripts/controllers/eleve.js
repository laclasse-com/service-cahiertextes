'use strict';

angular.module('publicAngularApp')
  .controller('EleveCtrl', function ($scope) {
    $scope.awesomeThings = [
      'HTML5 Boilerplate',
      'AngularJS',
      'Karma'
    ];
  })
  .controller('EleveDisplayController', function ($scope) {
    $scope.partToShow = 'Cours';
  });
