/* 
 * Filtres Angulars spécifiques à l'application Cahier de Textes
 */

// Tenir compte de la timezone dans les dates
angular.module('cahierDeTexteApp').filter('correctTimeZone', function() {
  return function(d) {
    var timezoneOffset = new Date(d).getTimezoneOffset() * 60000;
    return new Date(new Date(d) - timezoneOffset);
  };
});

// Afficher un créneau : date + heure de début et heure de fin
// ex : "Jeu 19 juin 15:00 - 16:00"
angular.module('cahierDeTexteApp').filter('formateCreneau', ['$filter', function($filter) {
  return function(creneau) {
    return $filter('date')(creneau.start, 'EEE dd MMM HH:mm') + ' - ' +$filter('date')(creneau.end, 'shortTime');
  };
}]);

