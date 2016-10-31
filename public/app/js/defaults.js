'use strict';

// Note: pour des raisons pratiques certaines constantes sémantiquement parlant sont en fait des factory ou des services

angular.module( 'cahierDeTextesClientApp' )
    .constant( 'LOCALHOST', false )
    .constant( 'API_VERSION', 'v1' )
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
// options des calendriers
    .factory( 'CALENDAR_OPTIONS', [ '$locale',
                                    function( $locale ) {
                                        return { lang: 'fr',
                                                 height: 600,
                                                 locale: 'fr',
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
    .constant( 'MULTIBARCHART_DEFINITION',
               { data: [],
                 options: { chart: { type: 'multiBarChart',
                                     height: 240,
                                     showControls: false,
                                     showLegend: true,
                                     showLabels: true,
                                     stacked: false,
                                     duration: 500,
                                     reduceXTicks: false,
                                     rotateLabels: -45,
                                     labelSunbeamLayout: true,
                                     color: function( d, i ) {
                                         var colors = { saisies: '#aaffaa',
                                                        visas: '#00ff00' };
                                         return colors[ d.key ];
                                     }
                                   }
                          }
               } )
    .constant( 'PIECHART_DEFINITION',
               { data: [ { label: 'saisie', value: 0 },
                         { label: 'valide', value: 0 } ],
                 options: { chart: { type: 'pieChart',
                                     height: 128,
                                     x: function( d ) { return d.label; },
                                     y: function( d ) { return d.value; },
                                     color: function( d, i ) {
                                         var colors = { saisies: '#aaffaa',
                                                        visas: '#00ff00' };
                                         return colors[ d.label ];
                                     },
                                     showLabels: false,
                                     showLegend: true,
                                     duration: 500,
                                     labelThreshold: 0.01,
                                     labelSunbeamLayout: true
                                   }
                          }
               } );
