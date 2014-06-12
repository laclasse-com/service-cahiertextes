/* 
 * Filtres Angulars spécifiques à l'application Cahier de Textes
 */
angular.module('cahierDeTexteApp').filter('correctTimeZone', function() {
  return function(d) {
    var timezoneOffset = new Date(d).getTimezoneOffset() * 60000;
    return new Date(new Date(d) - timezoneOffset);
  };
});

