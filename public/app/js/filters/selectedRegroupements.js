'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .filter('selectedRegroupements', function() {
        return function( creneaux, regroupements ) {
            var regroupements_ids = _(regroupements).pluck( 'id' );
            return _(creneaux).select( function( creneau ) {
                return _(regroupements_ids).contains( parseInt(creneau.regroupement_id) );
            } );
        };
    } );
