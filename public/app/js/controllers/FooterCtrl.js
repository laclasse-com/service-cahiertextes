'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('FooterCtrl',
                [ '$scope', '$state', '$stateParams', '$sce', 'VERSION', 'RELEASE_NOTES', 'User',
                  function ( $scope, $state, $stateParams, $sce, VERSION, RELEASE_NOTES, User ) {
                      var release_notes_to_html = function( release_notes ) {
                          var minor = _(release_notes).keys()[0];

                          var html = '<div class="release-notes"><h4>' + minor + '</h4>';
                          html += '<ul>';
                          html += _(release_notes[ minor ]).map( function( patch ) {
                              return '<li><h5>' + _(patch).keys()[0] + '</h5><ul>' + _(patch).map( function( item ) { return '<li>' + item + '</li>'; } ) + '</ul>';
                          } ).join('');
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
                              .success( function() {
                                  $state.transitionTo( $state.current, $stateParams, { reload: true, inherit: true, notify: true } );
                              } );
                      };
                  } );
                } ] );
