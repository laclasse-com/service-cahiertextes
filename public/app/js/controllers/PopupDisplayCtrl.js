'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('PopupDisplayCtrl',
                [ '$scope', '$sce', '$uibModalInstance', 'toastr', 'APP_PATH', 'DOCS_URL', 'Cours', 'Devoirs', 'User',
                  'titre', 'cours', 'devoirs',
                  function( $scope, $sce, $uibModalInstance, toastr, APP_PATH, DOCS_URL, Cours, Devoirs, User,
                            matiere, cours, devoirs ) {
                      $scope.app_path = APP_PATH;
                      $scope.matiere = matiere;
                      $scope.date = null;

                      if ( ! _(cours).isNull() ) {
                          $scope.cours = Cours.get( { id: cours.id } );
                          $scope.cours.$promise.then( function() {
                              _($scope.cours.ressources).each( function( ressource ) {
                                  ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
                              } );
                          } );

                          $scope.cours.$promise.then( function( cours ) {
                              $scope.date = $scope.cours.date_cours;
                              _(cours.devoirs).each( function( devoir ) {
                                  devoir.tooltip = devoir.contenu;
                                  if ( devoir.temps_estime > 0 ) {
                                      devoir.tooltip = '<span><i class="picto temps"></i>' + devoir.temps_estime * 5 + ' minutes</span><hr>' + devoir.tooltip;
                                  }
                                  devoir.tooltip = $sce.trustAsHtml( devoir.tooltip );
                              } );
                          } );
                      }

                      $scope.devoirs = devoirs.map( function( devoir ) {
                          return Devoirs.get( { id: devoir.id } );
                      } );
                      _($scope.devoirs).each( function( devoir ) {
                          devoir.$promise.then( function() {
                              devoir.cours.contenu = $sce.trustAsHtml( devoir.cours.contenu );
                              _(devoir.ressources).each( function( ressource ) {
                                  ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
                              } );
                          } );
                      } );
                      if ( _($scope.date).isNull() && !_($scope.devoirs).isEmpty() ) {
                          $scope.devoirs[0].$promise.then( function() {
                              $scope.date = $scope.devoirs[0].date_due;
                          } );
                      }

                      $scope.tab_SP_active = _($scope.devoirs).isEmpty();
                      $scope.fermer = function() {
                          $uibModalInstance.close( $scope );
                      };

                      User.get_user().then( function( response ) {
                          $scope.current_user = response.data;
                      } );
                  } ] );
