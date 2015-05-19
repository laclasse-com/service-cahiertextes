'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('ImportCtrl',
		[ '$scope', '$http', 'Upload', 'APP_PATH', 'Annuaire', 'current_user',
		  function ( $scope, $http, Upload, APP_PATH, Annuaire, current_user ) {
		      $scope.in_progress = false;
		      $scope.result = false;
		      $scope.fichiers = null;

		      $scope.onFileSelect = function( $files ) {
			  $scope.fichiers = $files;
		      };

		      $scope.launch_import = function( $files ) { // $files: an array of files selected, each file has name, size, and type.
			  $scope.result = false;

			  for ( var i = 0; i < $files.length; i++ ) {
			      var file = $files[ i ];
			      $scope.upload = Upload.upload( {
				  url: APP_PATH + '/api/v1/import/pronote',
				  method: 'POST',
				  file: file
			      } )
				  .progress( function( evt ) {
				      $scope.in_progress = true;
				      console.log('percent: ' + parseInt(100.0 * evt.loaded / evt.total));
				  } )
				  .error( function() {
				      $scope.in_progress = false;
				  } )
				  .success( function( data, status, headers, config ) {
				      $scope.in_progress = false;
				      $scope.result = data;

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
				  } );
			  }
		      };

		      angular.element('#ui-view-content').after( current_user.marqueur_xiti );
		  } ] );
