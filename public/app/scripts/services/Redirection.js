'use strict';

angular.module('cahierDeTexteApp')
    .service('Redirection',
	     [ '$location', '$state', 'User',
	       function( $location, $state, User ) {
		   this.doorman = function( allowed_types ) {
		       User.get_user().then( function( response ) {
			   if ( _( allowed_types ).indexOf( response.data['profil_actif']['type'] ) == -1 ) {
			       console.debug('redir vers '+response.data['profil_actif']['type'])
			       switch ( response.data['profil_actif']['type'] ) {
			       case 'DIR':
				   $state.transitionTo( 'principal.enseignants' );
				   break;
			       case'ENS':
				   $state.transitionTo( 'enseignant' );
				   break;
			       case 'ELV':
				   $state.transitionTo( 'eleve.emploi_du_temps' );
				   break;
			       default:
				   $location.url( '/logout' );
				   $location.replace();
			       }
			   }
		       } );
		   };
	       }
	     ] );
