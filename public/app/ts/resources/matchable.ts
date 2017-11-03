angular.module('cahierDeTextesClientApp')
  .factory('Matchable',
  ['$resource', 'APP_PATH',
    function($resource, APP_PATH) {
      return $resource(`${APP_PATH}/api/matchables/:uai/:hash_item`,
        {
          uai: '@uai',
          hash_item: '@hash_item',
          id_annuaire: '@id_annuaire'
        });
    }]);
