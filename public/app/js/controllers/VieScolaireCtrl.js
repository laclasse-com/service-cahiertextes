'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('VieScolaireCtrl',
		[ '$scope', '$state', '$sce', 'DOCS_URL',
		  function ( $scope, $state, $sce, DOCS_URL ) {
		      $scope.DOCS_URL_login = $sce.trustAsResourceUrl( DOCS_URL + '/login' );
		      $scope.tabs = [ { heading: 'Emplois du Temps',
					uisref: 'principal.emploi_du_temps',
					active: false } ];
		      _($scope.tabs).each( function( tab ) {
			  tab.active = tab.uisref == $state.current.name;
		      } );
		  } ] );
