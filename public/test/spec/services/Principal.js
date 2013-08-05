'use strict';

describe('Service: Principal', function () {

  // load the service's module
  beforeEach(module('cahierDeTexteApp'));

  // instantiate service
  var Principal;
  beforeEach(inject(function (_Principal_) {
    Principal = _Principal_;
  }));

  it('should do something', function () {
    expect(!!Principal).toBe(true);
  });

});
