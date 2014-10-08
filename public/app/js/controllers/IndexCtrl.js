'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('IndexCtrl',
		[ 'Redirection',
		  function ( Redirection ) {
		      Redirection.doorman( [  ] );
		  } ] );
