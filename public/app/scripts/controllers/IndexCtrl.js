'use strict';

angular.module('cahierDeTexteApp')
    .controller('IndexCtrl',
		[ '$location', '$state', 'User',
		  function ( $location, $state, User ) {
		      User.get_user().then( function( response ) {
			  var current_user = response.data;

			  var profil_etab = _(current_user.profils).find( function( p ) {
			      return p.uai == current_user.etablissement_actif;
			  } );

			  switch ( profil_etab.type ) {
			  case 'DIR':
			      $location.url( '/principal' );
			      break;
			  case 'ENS':
			      $location.url( '/enseignant' );
			      break;
			  case 'ELV':
			      $location.url( '/eleve' );
			      break;
			  }
			  $location.replace();
		      } );
		  } ] );
