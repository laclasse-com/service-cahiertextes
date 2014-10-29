'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('EnseignantCtrl',
		[ '$scope', '$state', 'current_user',
		  function ( $scope, $state, current_user ) {
		      $scope.tabs = [ { heading: 'Emploi du temps',
					uisref: 'enseignant.emploi_du_temps',
					css_class: 'glyphicon glyphicon-calendar',
					active: false },
				      { heading: 'Cahier de textes',
					uisref: 'enseignant.cahier_de_textes',
					css_class: 'glyphicon glyphicon-list',
					active: false },
				      { heading: 'Statistiques',
					uisref: 'enseignant.stats',
					css_class: 'glyphicon glyphicon-stats',
					active: false } ];
		      _($scope.tabs).each( function( tab ) {
			  tab.active = tab.uisref == $state.current.name;
		      } );

		      $scope.current_user = current_user;
		  } ] );
