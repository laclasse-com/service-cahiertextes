'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .config( [ '$httpProvider',
               function( $httpProvider ) {
                   $httpProvider.interceptors.push( [ '$q',
                                                      function( $q ) {
                                                          return {
                                                              'response': function( response ) {
                                                                  //Will only be called for HTTP up to 300
                                                                  return response;
                                                              },
                                                              'responseError': function( rejection ) {
                                                                  if ( rejection.status === 401 ) {
                                                                      swal( { title: 'Erreur',
                                                                              text: 'Votre session a expirée.',
                                                                              type: 'error',
                                                                              showCancelButton: false,
                                                                              confirmButtonColor: '#ff6b55',
                                                                              confirmButtonText: 'Fermer',
                                                                              timer: 3000
                                                                            } );
                                                                  }
                                                                  // if ( rejection.status === 500 ) {
                                                                  //     swal( { title: 'Erreur',
                                                                  //             text: 'L\'application a rencontrée une erreur durant le traitement serveur.',
                                                                  //             type: 'error',
                                                                  //             showCancelButton: false,
                                                                  //             confirmButtonColor: '#ff6b55',
                                                                  //             confirmButtonText: 'Fermer',
                                                                  //             timer: 3000
                                                                  //           } );
                                                                  // }
                                                                  return $q.reject( rejection );
                                                              }
                                                          };
                                                      } ] );
               } ] );
