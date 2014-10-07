'use strict';

angular.module( 'cahierDeTexteApp', [ 'ngResource',
				      'ngSanitize',
				      'ngLocale',
				      'ui.bootstrap',
				      'ui.bootstrap.dropdown',
				      'ui.calendar',
				      'ui.router',
				      'chieffancypants.loadingBar',
				      'ngAnimate',
				      'nvd3ChartDirectives',
				      'treeControl',
				      'angularMoment',
				      'theaquaNg',
				      'textAngular',
				      'angularFileUpload',
				      'ngColorPicker',
				      'ui.checkbox' ] )
    .run( function( amMoment ) {
	amMoment.changeLanguage( 'fr' );
    } );
