'use strict';

describe('Controller: PrincipalCtrl', function () {

  // load the controller's module
  beforeEach(module('cahierDeTexteApp'));

  var PrincipalCtrl,
    scope;

  // Initialize the controller and a mock scope
  beforeEach(inject(function ($controller, $rootScope) {
    scope = $rootScope.$new();
    PrincipalCtrl = $controller('PrincipalCtrl', {
      $scope: scope
    });
  }));

  it('should attach a list of awesomeThings to the scope', function () {
    expect(scope.awesomeThings.length).toBe(3);
  });
});
