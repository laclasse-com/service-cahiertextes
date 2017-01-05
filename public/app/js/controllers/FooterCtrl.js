'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('FooterCtrl',
                [ '$scope', '$state', '$stateParams', '$sce', 'VERSION', 'RELEASE_NOTES', 'User',
                  function ( $scope, $state, $stateParams, $sce, VERSION, RELEASE_NOTES, User ) {
                      var release_notes_to_html = function( release_notes ) {
                          var html = '<div class="release-notes"><h4>' + VERSION + '</h4>';
                          html += '<ul>';
                          html += _(release_notes).map( function( item ) { return '<li>' + item + '</li>'; } ).join('');
                          html += '</ul>';
                          html += '</div>';
                          html += '<sub>(<a href="https://github.com/laclasse-com/service-cahiertextes/blob/' + VERSION + '/RELEASE_NOTES.yaml">voir l\'historique complet</a>)</sub>';

                          return html;
                      };

                      $scope.version = VERSION;
                      $scope.release_notes = $sce.trustAsHtml( release_notes_to_html( RELEASE_NOTES ) );

                User.get_user().then( function( response ) {
                    $scope.current_user = response.data;

                    $scope.save_and_reload = function() {
                        User.update_parameters( $scope.current_user.parametrage_cahier_de_textes )
                            .then( function() {
                                $state.transitionTo( $state.current, $stateParams, { reload: true, inherit: true, notify: true } );
                            } );
                    };
                } );
               } ] );
