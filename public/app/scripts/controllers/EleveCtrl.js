'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveCtrl',
		[ '$scope', '$state',
		  function ( $scope, $state ) {
		      $scope.tabs = [ { heading: 'Emploi du temps',
					uisref: 'eleve.emploi_du_temps',
					active: false },
				      { heading: 'Travail à faire',
					uisref: 'eleve.devoirs',
					active: false } ];
		      _($scope.tabs).each( function( tab ) {
			  tab.active = tab.uisref == $state.current.name;
		      } );
		  } ] );
