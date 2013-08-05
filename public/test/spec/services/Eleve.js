'use strict';

describe('Service: Eleve', function () {

  // load the service's module
  beforeEach(module('cahierDeTexteApp'));

  // instantiate service
  var Eleve;
  beforeEach(inject(function (_Eleve_) {
    Eleve = _Eleve_;
  }));

  it('should do something', function () {
    expect(!!Eleve).toBe(true);
  });

});
