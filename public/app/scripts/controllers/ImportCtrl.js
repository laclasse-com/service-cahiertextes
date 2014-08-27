'use strict';

angular.module('cahierDeTexteApp')
    .controller('ImportCtrl',
		[ '$scope', '$upload', 'APP_PATH',
		  function ( $scope, $upload, APP_PATH ) {
		      $scope.in_progress = false;
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
				  .success( function( data, status, headers, config ) {
				      $scope.in_progress = false;
				  })
				  .error( function() {
				      $scope.in_progress = false;
				  });
			  }
		      };
		  } ] );
