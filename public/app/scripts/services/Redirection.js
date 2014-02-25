'use strict';

angular.module('cahierDeTexteApp')
    .service('Redirection',
	     [ '$location', '$state', 'User',
	       function( $location, $state, User ) {
		   this.doorman = function( allowed_types ) {
		       User.get_user().then( function( response ) {
			   var profils_utilisateur_pour_etablissement = _.chain( response.data.profils )
				   .where( { uai: response.data.etablissement_actif } )
				   .pluck( 'type' )
				   .value();

			   if ( _.chain( profils_utilisateur_pour_etablissement )
				.intersection( allowed_types )
				.isEmpty()
				.value() )
			   {
			       if ( _(profils_utilisateur_pour_etablissement).contains( 'DIR' ) ) {
				   $state.transitionTo( 'principal' );
			       } else if ( _(profils_utilisateur_pour_etablissement).contains( 'ENS' ) ) {
				   $state.transitionTo( 'enseignant' );
			       } else if ( _(profils_utilisateur_pour_etablissement).contains( 'ELV' ) ) {
				   $state.transitionTo( 'eleve' );
			       } else {
				   $location.url( '/logout' );
				   $location.replace();
			       }
			   }
		       } );
		   };
	       }
	     ] );
