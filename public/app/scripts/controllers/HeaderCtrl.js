'use strict';

angular.module('cahierDeTexteApp')
    .controller('HeaderCtrl',
		[ '$scope', 'User', 'Redirection',
		  function ( $scope, User, Redirection ) {
                      $scope.embedded = window != window.top;
		      User.get_user().success( function( response ) {
			  $scope.current_user = response;
		      });

		      $scope.reload = function() {
                          // Changement du profil actif dans l'annuaire
                          // Rechargement de l'application
			  Redirection.doorman( [  ] );
		      };
		  } ] );
