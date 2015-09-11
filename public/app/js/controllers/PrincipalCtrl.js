'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('PrincipalCtrl',
		[ '$scope', '$state',
		  function ( $scope, $state ) {
		      $scope.tabs = [ { heading: 'Validation des saisies par enseignant',
					uisref: 'principal.enseignants',
					css_class: 'glyphicon glyphicon-user',
					active: false },
				      { heading: 'Tableaux de bord par classe',
					uisref: 'principal.classes',
					css_class: 'glyphicon glyphicon-briefcase',
					active: false },
				      { heading: 'Emplois du Temps',
					uisref: 'principal.emploi_du_temps',
					css_class: 'glyphicon glyphicon-calendar',
					active: false }// ,
				      // { heading: 'Import Pronote',
				      //	uisref: 'principal.import',
				      //	css_class: 'glyphicon glyphicon-import',
				      //	active: false }
				    ];
		      _($scope.tabs).each( function( tab ) {
			  tab.active = tab.uisref == $state.current.name;
		      } );
		  } ] );
