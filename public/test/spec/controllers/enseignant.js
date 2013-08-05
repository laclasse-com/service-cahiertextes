'use strict';

describe('Controller: EnseignantCtrl', function () {

  // load the controller's module
  beforeEach(module('cahierDeTexteApp'));

  var EnseignantCtrl,
    scope;

  // Initialize the controller and a mock scope
  beforeEach(inject(function ($controller, $rootScope) {
    scope = $rootScope.$new();
    EnseignantCtrl = $controller('EnseignantCtrl', {
      $scope: scope
    });
  }));

  it('should attach a list of awesomeThings to the scope', function () {
    expect(scope.awesomeThings.length).toBe(3);
  });
});
