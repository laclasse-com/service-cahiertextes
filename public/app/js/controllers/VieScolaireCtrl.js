'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('VieScolaireCtrl',
		[ '$scope', '$state',
		  function ( $scope, $state ) {
		      $scope.tabs = [ { heading: 'Emplois du Temps',
					uisref: 'vie_scolaire.emploi_du_temps',
					css_class: 'glyphicon glyphicon-calendar',
					active: true } ];

		      _($scope.tabs).each( function( tab ) {
			  tab.active = tab.uisref == $state.current.name;
		      } );

		      $scope.set_active_tab = function( uisref ) {
			  _($scope.tabs).each( function( tab ) {
			      tab.active = tab.uisref == uisref;
			  } );
		      };
		  } ] );
