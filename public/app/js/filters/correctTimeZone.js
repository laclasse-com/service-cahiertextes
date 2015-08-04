/*
 * Filtres Angulars spécifiques à l'application Cahier de Textes
 */
'use strict';

// Tenir compte de la timezone dans les dates
angular.module( 'cahierDeTextesClientApp' )
    .filter( 'correctTimeZone',
	     function() {
		 return function( d ) {
		     d = new Date( d );
		     var timezoneOffset = d.getTimezoneOffset() / 60;
		     d.setHours( d.getHours() - timezoneOffset );
		     return d;
		 };
	     } );
