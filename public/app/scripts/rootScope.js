'use strict';

angular.module( 'cahierDeTexteApp' )
    .run( [ '$rootScope', function ($rootScope) {
    } ] );
		$rootScope.APP_VIRTUAL_PATH = '/ct';

		$rootScope.mois = [ 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre' ];
		// définition des couleurs
		$rootScope.theme = {
		    filled: { base: '#aaffaa',
			      stroke: '#88aa88' },
		    validated: { base: '#00ff00',
				 stroke: '#00aa00' },
		    calendar: { vide: '#a0a0a0',
				saisie: '#aaaaff',
				devoir: '#ff6666',
				devoir_fait: '#66cc66'}
		};

		// options des calendriers
		$rootScope.calendar = {	cours_max_length: 16,
					devoir_max_length: 16,
					couleurs: {
					    cours: '#ffc',
					    devoir: '#eff'
					}};
		$rootScope.globalCalendarOptions = {
		    timeFormat: 'H:mm{ - H:mm}',
		    columnFormat: { month: 'ddd',
				    week: 'ddd d/M',
				    day: 'dddd d MMMM' },
		    titleFormat: { month: 'MMMM yyyy',
				   week: "d MMM[ yyyy]{ '&#8212;' d [ MMM] yyyy}",
				   day: 'dddd d MMMM yyyy' },
		    monthNames: $rootScope.mois,
		    monthNamesShort: [ 'Jan.', 'Fév.', 'Mar.', 'Avr.', 'Mai', 'Juin', 'Juil.', 'Août', 'Sep.', 'Oct.', 'Nov.', 'Déc.' ],
		    dayNames: [ 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche' ],
		    dayNamesShort: [ 'Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.' ],
		    buttonText: { prev:     '&lsaquo;',
				  next:     '&rsaquo;',
				  prevYear: '&laquo;',
				  nextYear: '&raquo;',
				  today:    'aujourd\'hui',
				  month:    'mois',
				  week:     'semaine',
				  day:      'jour' }
		};

		// options de tinyMCE
		$rootScope.tinyMCEOptions = { menubar: false,
					      statusbar: false };

		// options des graphiques
		$rootScope.globalBarChartOptions = { animation : false,
						     scaleOverride: true,
						     scaleSteps : 0,
						     scaleStepWidth : 0,
						     scaleStartValue: 0 };
		$rootScope.globalPieChartOptions = { animation : false };
		$rootScope.globalLineChartOptions = { animation : false };
		$rootScope.globalRadarChartOptions = { animation : false };
