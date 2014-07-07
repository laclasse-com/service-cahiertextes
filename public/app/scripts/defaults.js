'use strict';

// Note: pour des raisons pratiques certaines constantes sémantiquement parlant sont en fait des factory ou des services

angular.module( 'cahierDeTexteApp' )
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
						 header: { left: 'today prev,next',
							   center: 'title',
							   right: '' },
						 firstDay: 1,
						 minTime: 7,
						 maxTime: 19,
						 ignoreTimezone: true,
						 timeFormat: { month: $locale.DATETIME_FORMATS.shortTime + '{ - ' + $locale.DATETIME_FORMATS.shortTime + '}',
							       week: '',
							       day: '' },
						 axisFormat: $locale.DATETIME_FORMATS.shortTime,
						 allDaySlot: false,
						 columnFormat: { month: 'ddd',
								 week: 'ddd d/M',
								 day: 'dddd d MMMM' },
						 titleFormat: { month: 'MMMM yyyy',
								week: "d[ MMM][ yyyy]{ '&#8212' d MMM yyyy}",
								day: 'dddd d MMMM yyyy' },
						 monthNames: $locale.DATETIME_FORMATS.MONTH,
						 monthNamesShort: $locale.DATETIME_FORMATS.SHORTMONTH,
						 dayNames: $locale.DATETIME_FORMATS.DAY,
						 dayNamesShort: $locale.DATETIME_FORMATS.SHORTDAY,
						 buttonText: { prev:     '&lsaquo;',
							       next:     '&rsaquo;',
							       prevYear: '&laquo;',
							       nextYear: '&raquo;',
							       today:    'aujourd\'hui',
							       month:    'mois',
							       week:     'semaine',
							       day:      'jour' },
						 defaultView: 'agendaWeek',
						 editable: false,
						 eventDurationEditable: false,
						 disableDragging: true,
						 selectable: false,
						 selectHelper: true
					       };
				    } ] )

// options de tinyMCE
    .constant( 'TINYMCE_OPTIONS', { menubar: false,
				    statusbar: false,
				    plugins: "textcolor paste autoresize",
				    toolbar: "styleselect | bold italic | link image | forecolor | backcolor",
				    insertdatetime_formats: ["%d/%m/%Y", "%H:%M"],
				    theme_advanced_font_sizes: "10px,12px,13px,14px,16px,18px,20px",
				    font_size_style_values: "12px,13px,14px,16px,18px,20px"
				  } )

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
