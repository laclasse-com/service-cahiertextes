'use strict';

angular.module('cahierDeTexteApp')
    .controller('FooterCtrl',
		[ '$scope', 'VERSION',
		  function ( $scope, VERSION ) {
		      $scope.version = VERSION;
		  } ] );
