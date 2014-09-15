'use strict';

angular.module('cahierDeTexteApp')
    .controller('ImportCtrl',
		[ '$scope', '$http', '$upload', 'APP_PATH', 'Annuaire', 'User',
		  function ( $scope, $http, $upload, APP_PATH, Annuaire, User ) {
		      $scope.in_progress = false;
		      $scope.result = false;

		      $scope.onFileSelect = function($files) {
			  //$files: an array of files selected, each file has name, size, and type.
			  for (var i = 0; i < $files.length; i++) {
			      var file = $files[i];
			      $scope.upload = $upload.upload({
				  url: APP_PATH + '/api/v1/import/pronote',
				  method: 'POST',
				  file: file
			      })
				  .progress( function( evt ) {
				      $scope.in_progress = true;
				      console.log('percent: ' + parseInt(100.0 * evt.loaded / evt.total));
				  })
				  .error( function() {
				      $scope.in_progress = false;
				  })
				  .success( function( data, status, headers, config ) {
				      $scope.in_progress = false;
				      $scope.result = data;

				      $scope.identifie_objet = function( sha256, id_annuaire ) {
					  $http.post( APP_PATH + '/api/v1/import/mrpni/' + sha256 + '/est/' + id_annuaire );
				      };

				      if ( !_($scope.result.rapport.matieres.error).isEmpty() ) {
					  // TODO
					  $scope.matieres = Annuaire.get_all_matieres();
				      }
				      if ( !_($scope.result.rapport.enseignants.error).isEmpty() ) {
					  // TODO
					  User.get_user().success( function ( response ) {
					      $scope.current_user = response;
					      $scope.enseignants = Annuaire.get_all_enseignants( { uai: $scope.current_user.profil_actif.uai } );
					  } );
				      }
				      if ( !_($scope.result.rapport.regroupements.error).isEmpty() ) {
					  // TODO
					  User.get_user().success( function ( response ) {
					      $scope.current_user = response;
					      $scope.enseignants = Annuaire.get_all_regroupements( { uai: $scope.current_user.profil_actif.uai } );
					  } );
				      }
				  });
			  }
		      };
		  } ] );
