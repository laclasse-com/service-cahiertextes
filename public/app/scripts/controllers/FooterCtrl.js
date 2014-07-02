'use strict';

angular.module('cahierDeTexteApp')
    .controller('FooterCtrl',
		[ '$scope', 'VERSION',
		  function ( $scope, VERSION ) {
		      console.debug(VERSION)
		      $scope.version = VERSION;
		  } ] );
