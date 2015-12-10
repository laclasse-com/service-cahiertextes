'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .filter( 'correctTimeZoneToGMT',
             function() {
                 return function( d ) {
                     var timezoneOffset = new Date( d ).getTimezoneOffset() / 60;
                     d.setHours( d.getHours() + timezoneOffset );
                     return d;
                 };
             } );
