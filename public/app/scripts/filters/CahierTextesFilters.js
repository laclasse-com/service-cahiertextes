/*
 * Filtres Angulars spécifiques à l'application Cahier de Textes
 */

// Tenir compte de la timezone dans les dates
angular.module( 'cahierDeTexteApp' )
    .filter( 'correctTimeZone', function () {
	return function ( d ) {
	    var timezoneOffset = new Date( d ).getTimezoneOffset() * 60000;
	    return new Date( new Date( d ) - timezoneOffset );
	};
    } )
    .filter( 'formateCreneau', [ '$filter',
	function ( $filter ) {
	    // Afficher un créneau : date + heure de début et heure de fin
	    // ex : "Jeu 19 juin 15:00 - 16:00"
	    return function ( creneau ) {
		return $filter( 'date' )( creneau.start, 'EEE dd MMM HH:mm' ) + ' - ' + $filter( 'date' )( creneau.end, 'shortTime' );
	    };
	}
    ] )
    .filter( 'cleverTruncate', function () {
	return function ( text, length ) {
	    if ( text.length > length ) {
		var result = text.substring( 0, length );
		result = result.substring( 0, result.lastIndexOf( ' ' ) );
		result += '…';

		return result;
	    } else {
		return text;
	    }
	};
    } );
