'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('VieScolaireCtrl',
		[ '$scope', '$state',
		  function ( $scope, $state ) {
		      $scope.tabs = [ { heading: 'Emplois du Temps',
					uisref: 'principal.emploi_du_temps',
					css_class: 'glyphicon glyphicon-calendar',
					active: false } ];
		      _($scope.tabs).each( function( tab ) {
			  tab.active = tab.uisref == $state.current.name;
		      } );
		  } ] );
