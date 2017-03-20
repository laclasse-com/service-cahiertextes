'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .filter( 'formateCreneau',
             [ '$filter',
               function( $filter ) {
                   // Afficher un créneau : date + heure de début et heure de fin
                   // ex : "Jeu 19 juin 15:00 - 16:00"
                   return function( creneau ) {
                       var label = '';

                       if ( _(creneau).has( 'start' ) ) {
                           label += $filter( 'amDateFormat' )( creneau.start, 'ddd DD MMM HH:mm' ) + ' - ' + $filter( 'amDateFormat' )( creneau.end, 'HH:mm' );
                       } else {
                           label += $filter( 'amDateFormat' )( creneau.heure_debut, 'ddd DD MMM HH:mm' ) + ' - ' + $filter( 'amDateFormat' )( creneau.heure_fin, 'HH:mm' );
                       }

                       return label;
                   };
               }
             ] );
