+function(angular) {
  var app = angular.module("mainApp", ["textAngular"]);
  
  app.controller("taCtrl", ["$scope", "textAngularManager", "$timeout", function($scope, textAngularManager, $timeout) {
    
    $scope.summary = '';
    $scope.textEditConfig = "[['bold','italics','ul','ol','insertLink']]";
    

  }]);

  app.config(function($provide) {

  });
}(window.angular);

