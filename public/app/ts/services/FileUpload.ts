'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .service( 'fileUpload',
  [ '$http',
    function( $http ) {
      this.uploadFileToUrl = function( file, uploadUrl, data ) {
        let fd = new FormData();
        fd.append( 'file', file );
        _.chain( data ).keys().each( function( key ) {
          fd.append( key, data[ key ] );
        } );

        return $http.post( uploadUrl, fd, {
          transformRequest: angular.identity,
          headers: { 'Content-Type': undefined }
        } );
      };
    }] );
