'use strict';

angular.module('cahierDeTexteApp')
    .controller('EnseignantCtrl',
		[ '$scope', '$state', 'User',
		  function ( $scope, $state, User ) {
		      $scope.tabs = [ { heading: 'Emploi du temps',
					uisref: 'enseignant.emploi_du_temps',
					active: false },
				      { heading: 'Cahier de textes',
					uisref: 'enseignant.cahier_de_textes',
					active: false },
				      { heading: 'Statistiques',
					uisref: 'enseignant.stats',
					active: false } ];
		      _($scope.tabs).each( function( tab ) {
			  tab.active = tab.uisref == $state.current.name;
		      } );

		      User.get_user().success( function( response ) {
			  $scope.current_user = response;
		      });
		  } ] );
