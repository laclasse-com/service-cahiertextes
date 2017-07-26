'use strict';

// Note: pour des raisons pratiques certaines constantes sémantiquement parlant sont en fait des factory ou des services

angular.module( 'cahierDeTextesClientApp' )
    .constant( 'LOCALHOST', false )
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
                                         var colors = { 'saisies non visées': '#aaffaa',
                                                        'saisies visées': '#00ff00' };
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
                                         var colors = { 'saisies non visées': '#aaffaa',
                                                        'saisies visées': '#00ff00' };
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
