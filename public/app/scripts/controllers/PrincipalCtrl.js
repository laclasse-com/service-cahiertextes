'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalCtrl',
		[ '$scope', '$state',
		  function ( $scope, $state ) {
		      $scope.tabs = [ { heading: 'Tableaux de bord par classe',
					uisref: 'principal.classes',
					active: false },
				      { heading: 'Validation des saisies par enseignant',
					uisref: 'principal.enseignants',
					active: false } ];
		      _($scope.tabs).each( function( tab ) {
			  tab.active = tab.uisref == $state.current.name;
		      } );
		  } ] );
