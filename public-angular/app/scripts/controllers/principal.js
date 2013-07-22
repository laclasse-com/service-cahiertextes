'use strict';

angular.module('publicAngularApp')
  .controller('PrincipalCtrl', function ($scope) {
    $scope.awesomeThings = [
      'HTML5 Boilerplate',
      'AngularJS',
      'Karma'
    ];
  });

angular.module('publicAngularApp')
  .controller('PrincipalClassesCtrl', function ($scope) {
    $scope.classes = [
      '3ème A',
      '6ème ZX',
      'Karma'
    ];
  });

angular.module('publicAngularApp')
  .controller('PrincipalEnseignantsCtrl', function ($scope) {
    $scope.enseignants = [
      'M. Raymond',
      'Melle Roux',
      'Maitre Hibou'
    ];
  });

angular.module('publicAngularApp')
  .controller('PrincipalEnseignantCtrl', function ($scope) {
    $scope.classes = [
      '3ème A',
      '6ème ZX'
    ];
  });
