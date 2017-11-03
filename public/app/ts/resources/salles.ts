angular.module('cahierDeTextesClientApp')
  .factory('Salles',
  ['$resource', 'APP_PATH',
    function($resource, APP_PATH) {
      return $resource(`${APP_PATH}/api/salles/:id`,
        { id: '@id' },
        {
          bulk: {
            method: 'POST',
            isArray: true,
            url: `${APP_PATH}/api/salles/bulk`,
            params: { salles: '@salles' }
          }
        });
    }])
