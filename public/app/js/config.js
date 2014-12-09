'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .config( [ 'cfpLoadingBarProvider',
	       function( cfpLoadingBarProvider ) {
		   // n'affiche la barre de chargement que si la requête prends plus de 0,5s
		   cfpLoadingBarProvider.latencyThreshold = 500;
	       } ] );
