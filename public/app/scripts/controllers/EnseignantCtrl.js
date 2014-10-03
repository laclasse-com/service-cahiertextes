'use strict';

angular.module('cahierDeTexteApp')
    .controller('EnseignantCtrl',
		[ '$scope', '$state', 'current_user',
		  function ( $scope, $state, current_user ) {
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

		      $scope.current_user = current_user;
		  } ] );
