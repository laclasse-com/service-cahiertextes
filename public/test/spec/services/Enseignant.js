'use strict';

describe('Service: Enseignant', function () {

  // load the service's module
  beforeEach(module('cahierDeTexteApp'));

  // instantiate service
  var Enseignant;
  beforeEach(inject(function (_Enseignant_) {
    Enseignant = _Enseignant_;
  }));

  it('should do something', function () {
    expect(!!Enseignant).toBe(true);
  });

});
