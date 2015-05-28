'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .config( [ '$compileProvider', 'LOCALHOST',
	       function( $compileProvider, LOCALHOST ) {
		   if ( ! LOCALHOST ) {
		       $compileProvider.debugInfoEnabled( false );
		   } else {
		       console.log( 'Riding http://localhost !' )
		   }
	       } ] )
    .config( [ 'cfpLoadingBarProvider',
	       function( cfpLoadingBarProvider ) {
		   // n'affiche la barre de chargement que si la requête prends plus de 0,5s
		   cfpLoadingBarProvider.latencyThreshold = 500;
	       } ] );
