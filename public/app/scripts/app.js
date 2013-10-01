'use strict';

angular.module( 'cahierDeTexteApp',
		[ 'ngResource', 'ui.bootstrap', 'ui.calendar', 'ui.router', 'ui.select2', 'ngGrid', 'angles' ] )
    .config( [ '$stateProvider', '$urlRouterProvider', function ( $stateProvider, $urlRouterProvider ) {
	$urlRouterProvider.otherwise('/');

	$stateProvider
	    .state('racine', {
		url: '/',
		templateUrl: 'views/main.html',
		controller: 'MainCtrl'
	    })
	    .state('principal', {
		url: '/principal',
		templateUrl: 'views/principal.html',
		controller: 'PrincipalCtrl'
	    })
	    .state('principal.classes', { //imbriquée sous principal
		parent: 'principal',
		url: '/classes',
		views: {
		    'titre': {
			template: 'Validation des saisies par Classe/Groupe'
		    },
		    'content': {
			templateUrl: 'views/principal.classes.html',
			controller: 'PrincipalClassesCtrl'
		    }
		}
	    })
	    .state('principal.enseignants', { //imbriquée sous principal
		parent: 'principal',
		url: '/enseignants',
		views: {
		    'titre': {
			template: 'Validation des saisies par Enseignants'
		    },
		    'content': {
			templateUrl: 'views/principal.enseignants.html',
			controller: 'PrincipalEnseignantsCtrl'
		    }
		}
	    })
	    .state('principal.enseignant', { //imbriquée sous principal
		parent: 'principal',
		url: '/enseignant/:enseignant_id',
		views: {
		    'titre': {
			template: 'Validation des saisies par Enseignant'
		    },
		    'content': {
			templateUrl: 'views/principal.enseignant.html',
			controller: 'PrincipalEnseignantCtrl'
		    }
		}
	    })
	    .state('eleve', {
		url: '/eleve',
		templateUrl: 'views/eleve.html',
		controller: 'EleveCtrl'
	    })
	    .state('enseignant', {
		url: '/enseignant',
		templateUrl: 'views/enseignant.html',
		controller: 'EnseignantCtrl'
	    });
    } ] )
    .run( [ '$rootScope', function ($rootScope) {
	// définition des couleurs
	$rootScope.theme = {
	    filled: { base: '#aaffaa',
		      stroke: '#88aa88' },
	    validated: { base: '#00ff00',
			 stroke: '#00aa00' }
	};
	$rootScope.globalPieChartOptions = { // segmentShowStroke : true,
					     // segmentStrokeColor : "#fff",
					     // segmentStrokeWidth : 0,
					     // percentageInnerCutout : 50,
					     // animation : true,
					     animationSteps : 24,
					     animationEasing : "easeOutQuart",
					     // animateRotate : true,
					     // animateScale : false,
					     // onAnimationComplete : null
					   };
	$rootScope.globalLineChartOptions = { // scaleOverlay : false,
					      // scaleOverride : false,
					      // scaleSteps : null,
					      // scaleStepWidth : null,
					      // scaleStartValue : null,
					      // scaleLineColor : "rgba(0,0,0,.1)",
					      // scaleLineWidth : 1,
					      // scaleShowLabels : true,
					      // scaleLabel : "<%=value%>",
					      // scaleFontFamily : "'Arial'",
					      // scaleFontSize : 12,
					      // scaleFontStyle : "normal",
					      // scaleFontColor : "#666",
					      // scaleShowGridLines : true,
					      // scaleGridLineColor : "rgba(0,0,0,.05)",
					      // scaleGridLineWidth : 1,
					      // bezierCurve : true,
					      // pointDot : true,
					      // pointDotRadius : 3,
					      // pointDotStrokeWidth : 1,
					      // datasetStroke : true,
					      // datasetStrokeWidth : 2,
					      // datasetFill : true,
					      // animation : true,
					      animationSteps : 24,
					      // animationEasing : "easeOutQuart",
					      // onAnimationComplete : null
					    };
	$rootScope.globalRadarChartOptions = { // scaleOverlay : false,
					       // scaleOverride : false,
					       // scaleSteps : null,
					       // scaleStepWidth : null,
					       // scaleStartValue : null,
					       // scaleShowLine : true,
					       // scaleLineColor : "rgba(0,0,0,.1)",
					       // scaleLineWidth : 1,
					       // scaleShowLabels : false,
					       // scaleLabel : "<%=value%>",
					       // scaleFontFamily : "'Arial'",
					       // scaleFontSize : 12,
					       // scaleFontStyle : "normal",
					       // scaleFontColor : "#666",
					       // scaleShowLabelBackdrop : true,
					       // scaleBackdropColor : "rgba(255,255,255,0.75)",
					       // scaleBackdropPaddingY : 2,
					       // scaleBackdropPaddingX : 2,
					       // angleShowLineOut : true,
					       // angleLineColor : "rgba(0,0,0,.1)",
					       // angleLineWidth : 1,			
					       // pointLabelFontFamily : "'Arial'",
					       // pointLabelFontStyle : "normal",
					       // pointLabelFontSize : 12,
					       // pointLabelFontColor : "#666",
					       // pointDot : true,
					       // pointDotRadius : 3,
					       // pointDotStrokeWidth : 1,
					       // datasetStroke : true,
					       // datasetStrokeWidth : 2,
					       // datasetFill : true,
					       // animation : true,
					       animationSteps : 24,
					       // animationEasing : "easeOutQuart",
					       // onAnimationComplete : null
					     };
    } ] );
