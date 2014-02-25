'use strict';

angular.module('cahierDeTexteApp')
    .service('Redirection',
	     [ '$location', 'User',
	       function( $location, User ) {
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
				   $location.url( '/principal' );
			       } else if ( _(profils_utilisateur_pour_etablissement).contains( 'ENS' ) ) {
				   $location.url( '/enseignant' );
			       } else if ( _(profils_utilisateur_pour_etablissement).contains( 'ELV' ) ) {
				   $location.url( '/eleve' );
			       } else {
				   $location.url( '/logout' );
			       }
			       $location.replace();
			   }
		       } );
		   };
	       }
	     ] );
