'use strict';

describe('Service: EmploiDuTemps', function () {

  // load the service's module
  beforeEach(module('publicAngularApp'));

  // instantiate service
  var EmploiDuTemps;
  beforeEach(inject(function (_EmploiDuTemps_) {
    EmploiDuTemps = _EmploiDuTemps_;
  }));

  it('should do something', function () {
    expect(!!EmploiDuTemps).toBe(true);
  });

});
