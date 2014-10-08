'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('PrincipalCtrl',
		[ '$scope', '$state',
		  function ( $scope, $state ) {
		      $scope.tabs = [ { heading: 'Validation des saisies par enseignant',
					uisref: 'principal.enseignants',
					active: false },
				      { heading: 'Tableaux de bord par classe',
					uisref: 'principal.classes',
					active: false },
				      { heading: 'Emplois du Temps',
					uisref: 'principal.emploi_du_temps',
					active: false },
				      { heading: 'Import Pronote',
					uisref: 'principal.import',
					active: false } ];
		      _($scope.tabs).each( function( tab ) {
			  tab.active = tab.uisref == $state.current.name;
		      } );
		  } ] );
