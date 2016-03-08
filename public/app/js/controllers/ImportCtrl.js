'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('ImportCtrl',
                [ '$scope', '$http', 'fileUpload', 'APP_PATH', 'Annuaire', 'current_user',
                  function ( $scope, $http, fileUpload, APP_PATH, Annuaire, current_user ) {
                      $scope.scope = $scope;
                      $scope.result = false;

                      $scope.launch_import = function( fichier ) {
                          $scope.result = false;

                          $scope.upload = fileUpload.uploadFileToUrl( fichier,
                                                                      APP_PATH + '/api/v1/import/pronote/decrypt',
                                                                      {} )
                              .then( function success( response, status, headers, config ) {
                                  $scope.result = response.data;
                              }, function error() {
                              } );
                      };

                      angular.element('#ui-view-content').after( current_user.marqueur_xiti );
                  } ] );
