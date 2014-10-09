/*
 * Filtres Angulars spécifiques à l'application Cahier de Textes
 */
'use strict';

// Tenir compte de la timezone dans les dates
angular.module( 'cahierDeTextesClientApp' )
    .filter( 'correctTimeZone',
	     function() {
		 return function( d ) {
		     var timezoneOffset = new Date( d ).getTimezoneOffset() * 60000;
		     return new Date( new Date( d ) - timezoneOffset );
		 };
	     } );
