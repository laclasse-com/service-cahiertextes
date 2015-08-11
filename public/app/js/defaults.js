'use strict';

// Note: pour des raisons pratiques certaines constantes sémantiquement parlant sont en fait des factory ou des services

angular.module( 'cahierDeTextesClientApp' )
    .constant( 'LOCALHOST', false )
    .constant( 'API_VERSION', 'v1' )
    .constant( 'SEMAINES_VACANCES', { A: [ 7, 8, 15, 16, 27, 28, 29, 30, 31, 32, 33, 34, 35, 43, 44 ],
				      B: [  ],
				      C: [  ] } )
    .constant( 'ZONE', 'A' )
    .constant( 'POPUP_ACTIONS', { CANCELLED: 'CANCELLED',
				  CRENEAU_DELETED: 'CRENEAU_DELETED',
				  CRENEAU_MODIFIED: 'CRENEAU_MODIFIED',
				  SEQUENCE_PEDAGOGIQUE_CREATED: 'SEQUENCE_PEDAGOGIQUE_CREATED',
				  SEQUENCE_PEDAGOGIQUE_MODIFIED: 'SEQUENCE_PEDAGOGIQUE_MODIFIED',
				  SEQUENCE_PEDAGOGIQUE_DUPLICATED: 'SEQUENCE_PEDAGOGIQUE_DUPLICATED',
				  SEQUENCE_PEDAGOGIQUE_DELETED: 'SEQUENCE_PEDAGOGIQUE_DELETED',
				  DEVOIR_CREATED: 'DEVOIR_CREATED',
				  DEVOIR_MODIFIED: 'DEVOIR_MODIFIED',
				  DEVOIR_DUPLICATED: 'DEVOIR_DUPLICATED',
				  DEVOIR_DELETED: 'DEVOIR_DELETED'
				} )
// .constant('angularMomentConfig', {
//	timezone: 'Europe/Paris'
// })
// définition des couleurs
    .constant( 'THEME', { filled: { base: '#aaffaa',
				    stroke: '#88aa88' },
			  validated: { base: '#00ff00',
				       stroke: '#00aa00' }
			} )

// options des calendriers
    .constant( 'CALENDAR_PARAMS', { max_length: 16,
				    couleurs: {
					'cours': '#ffc',
					'devoir': '#eff'
				    }} )
    .factory( 'CALENDAR_OPTIONS', [ '$locale',
				    function( $locale ) {
					return { lang: 'fr',
						 height: 600,
						 header: { left: '',
							   center: 'title',
							   right: 'today prev,next' },
						 firstDay: 1,
						 minTime: '07:00:00',
						 maxTime: '19:00:00',
						 businessHours: { start: '7:00',
								  end: '19:00',
								  dow: [ 1, 2, 3, 4, 5 ] },
						 timeFormat: ' ',
						 ignoreTimezone: false,
						 axisFormat: $locale.DATETIME_FORMATS.shortTime,
						 allDaySlot: false,
						 theme: false,
						 defaultView: 'agendaWeek',
						 editable: false,
						 eventDurationEditable: false,
						 eventStartEditable: false,
						 selectable: false,
						 selectHelper: true,
						 weekends: false
					       };
				    } ] )

// options des graphiques
    .factory( 'CHART_COLORS_FUNCTION', [ 'THEME',
					 function( THEME ) {
					     return function() {
						 var couleurs = [ THEME.validated.base, THEME.filled.base ];
						 return function( d, i ) {
						     return couleurs[ i ];
						 };
					     };
					 } ] )
    .service( 'BARCHART_DEFINITION', [ 'CHART_COLORS_FUNCTION',
				       function( CHART_COLORS_FUNCTION ) {
					   return function() {
					       return { data: [],
							tooltipContent: function() {
							    return function( key, x, y, e, graph ) {
								return '<h2>' + x + '</h2><p>' + y + ' ' + key + '</p>';
							    };
							},
							xAxisTickFormatFunction: function() { return function( d ) { return d; }; },
							colorFunction: CHART_COLORS_FUNCTION };
					   };
				       } ] )
    .service( 'PIECHART_DEFINITION', [ 'CHART_COLORS_FUNCTION',
				       function( CHART_COLORS_FUNCTION ) {
					   return function() {
					       return { data: [ { label: 'saisie', value: 0 },
								{ label: 'valide', value: 0 } ],
							xFunction: function(){ return function(d) { return d.label; }; },
							yFunction: function(){ return function(d) { return d.value; }; },
							colorFunction: CHART_COLORS_FUNCTION };
					   };
				       } ] );
