'use strict';

angular.module( 'cahierDeTexteApp', [ 'ngResource',
				      'ngSanitize',
				      'ngLocale',
				      'ui.bootstrap',
				      'ui.calendar',
				      'ui.router',
				      'ngGrid',
				      'chieffancypants.loadingBar',
				      'ngAnimate',
				      'nvd3ChartDirectives',
				      'treeControl',
				      'angularMoment',
				      'theaquaNg',
				      'textAngular',
				      'angularFileUpload' ] )
    .run( function( amMoment ) {
	amMoment.changeLanguage( 'fr' );
    } );
