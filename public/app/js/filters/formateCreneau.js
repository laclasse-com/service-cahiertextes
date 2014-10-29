/*
 * Filtres Angulars spécifiques à l'application Cahier de Textes
 */
'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .filter( 'formateCreneau',
	     [ '$filter',
	       function( $filter ) {
		   // Afficher un créneau : date + heure de début et heure de fin
		   // ex : "Jeu 19 juin 15:00 - 16:00"
		   return function( creneau ) {
		       if ( _(creneau).has( 'start' ) ) {
			   return $filter( 'date' )( creneau.start, 'EEE dd MMM HH:mm' ) + ' - ' + $filter( 'date' )( creneau.end, 'shortTime' );
		       } else {
			   return $filter( 'date' )( creneau.heure_debut, 'EEE dd MMM HH:mm' ) + ' - ' + $filter( 'date' )( creneau.heure_fin, 'shortTime' );
		       }
		   };
	       }
	     ] );
