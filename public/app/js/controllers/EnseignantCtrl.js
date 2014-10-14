'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('EnseignantCtrl',
		[ '$scope', '$state', 'current_user', '$sce', 'DOCS_URL',
		  function ( $scope, $state, current_user, $sce, DOCS_URL ) {
		      $scope.DOCS_URL_login = $sce.trustAsResourceUrl( DOCS_URL + '/login' );
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
