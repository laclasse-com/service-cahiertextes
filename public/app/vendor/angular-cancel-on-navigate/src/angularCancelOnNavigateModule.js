/**
 * angular-cancel-on-navigate - AngularJS module that cancels HTTP requests on location change (navigation)
 * @version v0.1.1
 * @link https://github.com/billyaraujo/angular-cancel-on-navigate
 * @license MIT
 */
angular
  .module('angularCancelOnNavigateModule', [])
  .config(['$httpProvider', function($httpProvider) {
    $httpProvider.interceptors.push('HttpRequestTimeoutInterceptor');
  }])
  .run(['$rootScope', 'HttpPendingRequestsService', function ($rootScope, HttpPendingRequestsService) {
    $rootScope.$on('$locationChangeSuccess', function (event, newUrl, oldUrl) {
      if (newUrl != oldUrl) {
        HttpPendingRequestsService.cancelAll();
      }
    });
  }]);

angular.module('angularCancelOnNavigateModule')
  .service('HttpPendingRequestsService', ['$q', function ($q) {
    var cancelPromises = [];

    function newTimeout() {
      var cancelPromise = $q.defer();
      cancelPromises.push(cancelPromise);
      return cancelPromise.promise;
    }

    function cancelAll() {
      angular.forEach(cancelPromises, function (cancelPromise) {
        cancelPromise.promise.isGloballyCancelled = true;
        cancelPromise.resolve();
      });
      cancelPromises.length = 0;
    }

    return {
      newTimeout: newTimeout,
      cancelAll: cancelAll
    };
  }]);

angular.module('angularCancelOnNavigateModule')
  .factory('HttpRequestTimeoutInterceptor', ['$q', 'HttpPendingRequestsService', function ($q, HttpPendingRequestsService) {
    return {
      request: function (config) {
        config = config || {};
        if (config.timeout === undefined && config.cancelOnRouteChange) {
          config.timeout = HttpPendingRequestsService.newTimeout();
        }
        return config;
      },

      responseError: function (response) {
        return $q.reject(response);
      }
    };
  }]);
