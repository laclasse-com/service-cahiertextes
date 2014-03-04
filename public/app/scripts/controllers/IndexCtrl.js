'use strict';

angular.module('cahierDeTexteApp')
    .controller('IndexCtrl',
		[ 'Redirection',
		  function ( Redirection ) {
		      Redirection.doorman( [  ] );
		  } ] );
