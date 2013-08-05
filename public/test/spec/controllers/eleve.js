'use strict';

describe('Controller: LVeCtrl', function () {

  // load the controller's module
  beforeEach(module('cahierDeTexteApp'));

  var LVeCtrl,
    scope;

  // Initialize the controller and a mock scope
  beforeEach(inject(function ($controller, $rootScope) {
    scope = $rootScope.$new();
    LVeCtrl = $controller('LVeCtrl', {
      $scope: scope
    });
  }));

  it('should attach a list of awesomeThings to the scope', function () {
    expect(scope.awesomeThings.length).toBe(3);
  });
});
