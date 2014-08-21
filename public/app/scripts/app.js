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
				      'frapontillo.bootstrap-switch',
				      'textAngular' ] )
    .run( function( amMoment ) {
	amMoment.changeLanguage( 'fr' );
    } );
