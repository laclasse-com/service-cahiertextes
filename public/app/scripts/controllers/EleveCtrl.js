'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveCtrl',
		[ '$scope', '$state', 'User',
		  function ( $scope, $state, User ) {
		      $scope.tabs = [ { heading: 'Emploi du temps',
					uisref: 'eleve.emploi_du_temps',
					active: false },
				      { heading: 'Liste des devoirs',
					uisref: 'eleve.devoirs',
					active: false } ];
		      _($scope.tabs).each( function( tab ) {
			  tab.active = tab.uisref == $state.current.name;
		      } );

		      User.get_user().then( function( response ) {
			  $scope.current_user = response.data;

			  $scope.reload = function() {
			      $state.reload();
			  };
		      } );
		  } ] );
