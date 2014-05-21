'use strict';

angular.module( 'cahierDeTexteApp' )
    .constant( 'APP_VIRTUAL_PATH', '/ct' )

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
						 header: { left: 'title',
							   center: 'agendaDay agendaWeek month',
							   right: 'today prev,next' },
						 firstDay: 1,
						 minTime: 7,
						 maxTime: 19,
						 ignoreTimezone: false,
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
						 selectable: true,
						 selectHelper: true
					       };
				    } ] )

// options de tinyMCE
    .constant( 'TINYMCE_OPTIONS', { menubar: false,
				    statusbar: false,
				    plugins: "textcolor paste contextmenu autoresize",
				    toolbar: "undo redo | styleselect | bold italic | link image | forecolor | backcolor",
				    contextmenu: "bold italic",
				    insertdatetime_formats: ["%d/%m/%Y", "%H:%M"]

				  } )

// options des graphiques
    .constant( 'BARCHART_OPTIONS', { animation : false } )
    .constant( 'PIECHART_OPTIONS', { animation : false } )
    .constant( 'LINECHART_OPTIONS', { animation : false } )
    .constant( 'RADARCHART_OPTIONS', { animation : false } );
