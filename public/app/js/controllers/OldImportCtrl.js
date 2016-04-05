'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('OldImportCtrl',
                [ '$scope', '$http', 'fileUpload', 'APP_PATH', 'Annuaire', 'current_user',
                  function ( $scope, $http, fileUpload, APP_PATH, Annuaire, current_user ) {
                      $scope.scope = $scope;
                      $scope.in_progress = false;
                      $scope.result = false;
                      $scope.fichier = null;

                      $scope.second_pass = false;

                      $scope.launch_import = function( fichier ) {
                          swal( { type: 'info',
                                  title: $scope.second_pass ? 'Import des données en cours.' : 'Vérification et recollement des données en cours',
                                  text: 'Merci de bien vouloir patienter, cette opération peut être longue (jusqu\'à 10 minutes).',
                                  showCancelButton: false,
                                  showConfirmButton: false
                                } );

                          $scope.result = false;

                          $scope.upload = fileUpload.uploadFileToUrl( fichier,
                                                                      APP_PATH + '/api/v1/import/pronote',
                                                                      { create_creneaux: $scope.second_pass } )
                              .then( function success( response, status, headers, config ) {
                                  $scope.in_progress = false;
                                  $scope.result = response.data;

                                  $scope.identifie_objet = function( mrpni ) {
                                      if ( _(mrpni).has('id_annuaire')
                                           && !_(mrpni.id_annuaire).isNull()
                                           && !_(mrpni.id_annuaire).isUndefined() ) {
                                          $http.put( APP_PATH + '/api/v1/import/mrpni/' + mrpni.sha256 + '/est/' + mrpni.id_annuaire )
                                              .success( function() {
                                                  mrpni.identified = true;
                                              });
                                      }
                                  };
                                  $scope.identifie_massivement_objets = function( mrpnis ) {
                                      _(mrpnis).each( function( mrpni ) {
                                          $scope.identifie_objet( mrpni );
                                      } );
                                  };

                                  if ( !_($scope.result.rapport.matieres.error).isEmpty() ) {
                                      Annuaire.get_matieres()
                                          .then( function( response ) {
                                              $scope.matieres = response.data;
                                          } );
                                  }
                                  if ( !_($scope.result.rapport.enseignants.error).isEmpty() ) {
                                      $scope.current_user = current_user;
                                      Annuaire.get_etablissement_enseignants( $scope.current_user.profil_actif.etablissement_code_uai )
                                          .then( function( response ) {
                                              $scope.enseignants = response.data;
                                          } );
                                  }
                                  if ( !_($scope.result.rapport.regroupements.Classe.error).isEmpty()
                                       || !_($scope.result.rapport.regroupements.Groupe.error).isEmpty()
                                       || !_($scope.result.rapport.regroupements.PartieDeClasse.error).isEmpty() ) {
                                      $scope.current_user = current_user;
                                      Annuaire.get_etablissement_regroupements( $scope.current_user.profil_actif.etablissement_code_uai )
                                          .then( function( response ) {
                                              $scope.regroupements = response.data;
                                          } );
                                  }

                                  swal( { type: 'success',
                                          title: $scope.second_pass ? 'Les données ont été importées dans le Cahier de Textes avec succès.' : 'Les recollements possibles ont été fait.',
                                          text: 'S\'il subsiste des éléments n\'ayant pû être identifiés nous vous demandons de faire le recollement manuellement puis de relancer le processus d\'import en cliquant sur le bouton « Ré-importer ».',
                                          showCancelButton: false
                                        } );

                                  $scope.second_pass = true;
                              }, function error() {
                                  $scope.in_progress = false;
                                  swal( { type: 'error',
                                          title: 'Erreur lors de l\'importation.',
                                          text: 'Merci de contacter le support.',
                                          showCancelButton: false
                                        } );
                              } );
                      };
                  } ] );
