'use strict';

cahierDeTexteApp
    .controller('HeaderCtrl',
		[ '$scope', '$state', 'User', 'Redirection',
		  function ( $scope, $state, User, Redirection ) {
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
