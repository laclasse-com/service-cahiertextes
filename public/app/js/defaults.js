'use strict';

// Note: pour des raisons pratiques certaines constantes sémantiquement parlant sont en fait des factory ou des services

angular.module( 'cahierDeTextesClientApp' )
    .constant( 'LOCALHOST', function() {
	return location.host.match( /localhost/ );
    } )
    .constant( 'API_VERSION', 'v1' )
    .constant( 'SEMAINES_VACANCES', { A: [ 1, 7, 8, 16, 17, 28, 29, 30, 31, 32, 33, 34, 43, 44 ],
				      B: [ 1, 7, 8, 16, 17, 28, 29, 30, 31, 32, 33, 34, 43, 44 ],
				      C: [ 1, 7, 8, 16, 17, 28, 29, 30, 31, 32, 33, 34, 43, 44 ] } )
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
					return { height: 600,
						 header: { left: '',
							   center: 'title',
							   right: 'today prev,next' },
						 firstDay: 1,
						 minTime: '07:00:00',
						 maxTime: '19:00:00',
						 ignoreTimezone: true,
						 axisFormat: $locale.DATETIME_FORMATS.shortTime,
						 allDaySlot: false,
						 monthNames: $locale.DATETIME_FORMATS.MONTH,
						 monthNamesShort: $locale.DATETIME_FORMATS.SHORTMONTH,
						 dayNames: $locale.DATETIME_FORMATS.DAY,
						 dayNamesShort: $locale.DATETIME_FORMATS.SHORTDAY,
						 theme: false,
						 buttonIcons: { prev:     'left-single-arrow',
								next:     'right-single-arrow',
								prevYear: 'left-double-arrow',
								nextYear: 'right-double-arrow' },
						 buttonText: { today: 'aujourd\'hui',
							       month: 'mois',
							       week:  'semaine',
							       day:   'jour' },
						 views: {
						     basic: { titleFormat: 'MMMM YYYY',
							      columnFormat: 'ddd',
							      timeFormat: ' ' }, //$locale.DATETIME_FORMATS.shortTime + '{ - ' + $locale.DATETIME_FORMATS.shortTime + '}' },
						     agenda: { titleFormat: 'MMMM YYYY',
							       columnFormat: 'ddd',
							       timeFormat: ' ' }, //$locale.DATETIME_FORMATS.shortTime + '{ - ' + $locale.DATETIME_FORMATS.shortTime + '}' },
						     week: { titleFormat: '[Semaine du] D MMMM YYYY',
							     columnFormat: 'ddd D/M',
							     timeFormat: ' ' },
						     day: { titleFormat: 'DDDD D MMMM YYYY',
							    columnFormat: 'DDDD D MMMM',
							    timeFormat: ' ' }
						 },
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
