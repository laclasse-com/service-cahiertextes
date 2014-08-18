'use strict';

angular.module('cahierDeTexteApp')
    .service( 'Redirection',
	      [ '$location', '$state', 'User',
		function( $location, $state, User ) {
		    this.doorman = function( allowed_types ) {
			User.get_user().then(function( response ) {
			    if (_(allowed_types).size() === 0 ||
                                   ( _(allowed_types).indexOf( response.data['profil_actif']['type'] ) === -1
			      && !response.data['profil_actif']['admin'] )
			     ) {
				 // traiter le raffraichissement de l'app en fonction du changement de profil actif
				 var reloadStatus = true;
				 var stateName = '';

				 switch ( response.data['profil_actif']['type'] ) {
				 case 'DIR':
				     stateName = 'principal.enseignants';
				     break;
				 case 'ENS':
				     stateName = 'enseignant.emploi_du_temps';
				     break;
				 case 'ELV':
				     stateName = 'eleve.emploi_du_temps';
				     break;
				 default:
				     stateName = '404';
				 }
				 reloadStatus = ( $state.current.name == 'index' || $state.current.name == stateName ) ? true : false;
				 $state.transitionTo( stateName, $state.params, { reload: reloadStatus, inherit: false, notify: reloadStatus } );
			     }
		      });
		  };
	      }
	     ]);
