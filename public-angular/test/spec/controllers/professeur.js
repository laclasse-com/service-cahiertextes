'use strict';

describe('Controller: ProfesseurCtrl', function () {

  // load the controller's module
  beforeEach(module('publicAngularApp'));

  var ProfesseurCtrl,
    scope;

  // Initialize the controller and a mock scope
  beforeEach(inject(function ($controller, $rootScope) {
    scope = $rootScope.$new();
    ProfesseurCtrl = $controller('ProfesseurCtrl', {
      $scope: scope
    });
  }));

  it('should attach a list of awesomeThings to the scope', function () {
    expect(scope.awesomeThings.length).toBe(3);
  });
});
