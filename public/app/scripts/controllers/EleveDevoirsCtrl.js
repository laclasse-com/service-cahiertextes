'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveDevoirsCtrl',
		[ '$scope',
		  function ( $scope ) {
		      $scope.devoirs = [ 'test1',
					 'test2',
					 'test3',
					 'test4',
					 'test5' ];
		  } ] );
