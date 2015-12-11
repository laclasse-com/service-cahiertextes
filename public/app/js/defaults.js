'use strict';

// Note: pour des raisons pratiques certaines constantes sémantiquement parlant sont en fait des factory ou des services

angular.module( 'cahierDeTextesClientApp' )
    .constant( 'LOCALHOST', false )
    .constant( 'API_VERSION', 'v1' )
    .constant( 'SEMAINES_VACANCES', { A: [ 7, 8, 15, 16, 27, 28, 29, 30, 31, 32, 33, 34, 35, 43, 44, 52, 53 ],
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
// options des calendriers
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
    .service( 'MULTIBARCHART_DEFINITION',
              function() {
                  return function() {
                      return { data: [ { label: 'saisie', value: 0 },
                                       { label: 'valide', value: 0 } ],
                               options: { chart: { type: 'multiBarChart',
                                                   height: 128,
                                                   x: function( d ) { return d.label; },
                                                   y: function( d ) { return d.value; },
                                                   showLabels: false,
                                                   showLegend: true,
                                                   // legend: { margin: { top: 5,
                                                   //                     right: 150,
                                                   //                     bottom: 0,
                                                   //                     left: 0
                                                   //                   }
                                                   //         },
                                                   duration: 500,
                                                   labelThreshold: 0.01,
                                                   labelSunbeamLayout: true
                                                 }
                                        }
                             };
                  };
              } )
    .service( 'PIECHART_DEFINITION',
              function() {
                  return function() {
                      return { data: [ { label: 'saisie', value: 0 },
                                       { label: 'valide', value: 0 } ],
                               options: { chart: { type: 'pieChart',
                                                   height: 128,
                                                   x: function( d ) { return d.label; },
                                                   y: function( d ) { return d.value; },
                                                   showLabels: false,
                                                   showLegend: true,
                                                   // legend: { margin: { top: 5,
                                                   //                     right: 150,
                                                   //                     bottom: 0,
                                                   //                     left: 0
                                                   //                   }
                                                   //         },
                                                   duration: 500,
                                                   labelThreshold: 0.01,
                                                   labelSunbeamLayout: true
                                                 }
                                        }
                             };
                  };
              } );
