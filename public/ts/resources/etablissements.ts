angular.module('cahierDeTextesClientApp')
  .factory('Etablissements',
  ['$resource', 'APP_PATH',
    function($resource, APP_PATH) {
      return $resource(`${APP_PATH}/api/etablissements/:uai`,
        { uai: '@uai' });
    }])
