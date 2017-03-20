'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .component( 'switchDevoir',
                { bindings: { devoir: '=' },
                  template: '<span switch' +
                  '      class="violet"' +
                  '      ng:if="!($ctrl.devoir.type_devoir_id == 1)"' +
                  '      ng:model="$ctrl.devoir.fait"' +
                  '      ng:change="$ctrl.fait( $ctrl.devoir )" ></span>',
                  controller: [ 'toastr',
                                function( toastr ) {
                                    var ctrl = this;

                                    ctrl.fait = function( devoir ) {
                                        devoir.$fait()
                                            .then( function( response ) {
                                                if ( response.fait ) {
                                                    toastr.success( 'Devoir fait.',
                                                                    'Bravo !' );
                                                } else {
                                                    toastr.info( 'Devoir à faire',
                                                                 'Encore un petit effort.' );
                                                }
                                            } );
                                    };
                                } ]
                } );
