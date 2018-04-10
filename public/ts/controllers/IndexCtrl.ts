'use strict';

angular.module('cahierDeTextesClientApp')
  .controller('IndexCtrl',
              ['$scope',
               function($scope) {
                 let ctrl = $scope;
                 ctrl.$ctrl = ctrl;

                 ctrl.embedded = window != window.top;
               }]);
