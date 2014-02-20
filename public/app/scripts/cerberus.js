'use strict';

angular.module( 'cahierDeTexteApp' )
    .run( [ '$rootScope', '$location', 'User',
	    function ( $rootScope, $location, User ) {
		$rootScope.$on( '$stateChangeStart',
				function( event, toState, toParams, fromState, fromParams ) {
				    User.get_user().then( function( response ) {
					var current_user = response.data;
					var allowed = _(current_user.profils).reduce( function( autorise, profil ) {
					    return autorise && _(toState.data.auth).contains( profil.type );
					}, true );

					if ( allowed ) {
					    return true;
					} else {

					    var profil_etab = _(current_user.profils).find( function( p ) {
						return p.uai == current_user.ENTPersonStructRattachRNE;
					    });

					    switch ( profil_etab.type ) {
					    case 'DIR':
						console.log('redirection vers /principal')
						$location.url( '/principal' );
						break;
					    case 'ENS':
						console.log('redirection vers /enseignant')
						$location.url( '/enseignant' );
						break;
					    case 'ELV':
						console.log('redirection vers /eleve')
						$location.url( '/eleve' );
						break;
					    }

					    console.debug(current_user)
					    event.preventDefault();
					    $location.replace();
					    return false;
					}
				    } );
				} );
	    } ] );
