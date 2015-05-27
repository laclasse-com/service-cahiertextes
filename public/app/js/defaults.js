'use strict';

// Note: pour des raisons pratiques certaines constantes sémantiquement parlant sont en fait des factory ou des services

angular.module( 'cahierDeTextesClientApp' )
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
// Configuration d'angular-moment
    .run( [ 'amMoment',
	    function( amMoment ) {
		amMoment.changeLocale( 'fr' );
	    } ] )
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
				       } ] )
    .config( [ '$provide',
	       function( $provide ) {
		   // configuration de textAngular
		   $provide.decorator( 'taOptions',
				       [ '$delegate', 'taRegisterTool',
					 function( taOptions, taRegisterTool ){
					     taOptions.toolbar = [
						 [ 'bold', 'italics', 'underline', 'ul', 'ol', 'quote', 'justifyLeft', 'justifyCenter', 'justifyRight', 'insertLink', 'html', 'redo', 'undo' ]
					     ];

					     var colorpicker_taTool = function( type ) {
						 var style = ( type === 'backcolor' ) ? 'background-' : '';
						 var couleurs = [ '#7bd148', '#5484ed', '#a4bdfc', '#46d6db', '#7ae7bf', '#51b749', '#fbd75b', '#ffb878', '#ff887c', '#dc2127', '#dbadff', '#e1e1e1' ];
						 if ( type === 'backcolor' ) {
						     couleurs.push( 'transparent' );
						 }

						 return { couleurs: couleurs,
							  display: '<span dropdown class="dropdown"><a dropdown-toggle class="dropdown-toggle"><i class="fa fa-font" data-ng-style="{\'' + style + 'color\': selected }"></i> <i class="fa fa-caret-down"></i></a><ng-color-picker dropdown-menu class="dropdown-menu" selected="selected" colors="couleurs"></ng-color-picker></span>',
							  action: function( ) {
							      return ( this.selected === 'nil' ) ? false : this.$editor().wrapSelection( type, this.selected );
							  }
							};
					     };

					     taRegisterTool( 'fontColor', colorpicker_taTool( 'forecolor' ) );
					     taOptions.toolbar[0].push( 'fontColor' );

					     taRegisterTool( 'backgroundColor', colorpicker_taTool( 'backcolor' ) );
					     taOptions.toolbar[0].push( 'backgroundColor' );

					     taRegisterTool( 'table', { columns: { value: 1,
										   hovered: 1 },
									rows: { value: 1,
										hovered: 1 },
									hover: function( objet, value ) {
									    objet.hovered = value;
									},
									leave: function( objet ) {
									    objet.hovered = objet.value;
									},
									tooltiptext: 'insérer un tableau',
									display: '<span dropdown class="dropdown"><a dropdown-toggle class="dropdown-toggle"><i class="fa fa-table"></i> <i class="fa fa-caret-down"></i></a><div dropdown-menu class="dropdown-menu" data-ng-click="$event.stopPropagation()"><label><rating on-hover="hover( columns, value )" on-leave="leave( columns )" ng-model="columns.value" max="15" state-on="\'glyphicon-stop\'" state-off="\'glyphicon-unchecked\'"></rating><br>{{columns.hovered}} colonnes</label><br><label><rating on-hover="hover( rows, value )" on-leave="leave( rows )" ng-model="rows.value" max="15" state-on="\'glyphicon-stop\'" state-off="\'glyphicon-unchecked\'"></rating><br>{{rows.hovered}} lignes</label><br><button class="btn btn-success" data-ng-click="insert_table()">Insérer</button></div></span>',
									insert_table: function(  ) {
									    var tds = '';
									    for ( var idxCol = 0; idxCol < this.columns.value; idxCol++ ) {
										tds = tds + '<td>&nbsp;</td>';
									    }
									    var trs = '';
									    for ( var idxRow = 0; idxRow < this.rows.value; idxRow++ ) {
										trs = trs + '<tr>'+ tds + '</tr>';
									    }

									    this.$editor().wrapSelection( 'insertHTML', '<table class="table table-bordered">' + trs + '</table>' );

									    this.deferration.resolve();
									},
									action: function( deferred  ) {
									    this.deferration = deferred;
									    return false;
									} } );
					     taOptions.toolbar[0].push( 'table' );

					     taOptions.classes = {
						 focussed: 'focussed',
						 toolbar: 'btn-toolbar',
						 toolbarGroup: 'btn-group',
						 toolbarButton: 'btn btn-default',
						 toolbarButtonActive: 'active',
						 disabled: 'disabled',
						 textEditor: 'form-control',
						 htmlEditor: 'form-control'
					     };
					     return taOptions;
					 } ] );

		   $provide.decorator( 'taTools',
				       [ '$delegate',
					 function( taTools ){
					     taTools.html.buttontext = 'HTML';

					     return taTools;
					 } ] );
	       } ] )
    .config( [ 'toastrConfig',
	       function( toastrConfig ) {
		   angular.extend(toastrConfig, {
		       allowHtml: true,
		       closeButton: false,
		       closeHtml: '<button>&times;</button>',
		       containerId: 'toast-container',
		       extendedTimeOut: 1000,
		       iconClasses: {
			   error: 'toast-error',
			   info: 'toast-info',
			   success: 'toast-success',
			   warning: 'toast-warning'
		       },
		       maxOpened: 0,
		       messageClass: 'toast-message',
		       newestOnTop: true,
		       onHidden: null,
		       onShown: null,
		       positionClass: 'toast-bottom-right',
		       tapToDismiss: true,
		       target: 'body',
		       timeOut: 5000,
		       titleClass: 'toast-title',
		       toastClass: 'toast'
		   } );
	       } ] );
