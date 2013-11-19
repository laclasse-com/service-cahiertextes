'use strict';

angular.module('cahierDeTexteApp')
  .factory('Matieres',
	   [ '$resource',
	     function( $resource ) {
		 return $resource( '/api/v0/annuaire/matieres/:matiere_id',
				   { matiere_id: '@matiere_id' } );
	     } ] );

angular.module('cahierDeTexteApp')
  .factory('Regroupements',
	   [ '$resource',
	     function( $resource ) {
		 return $resource( '/api/v0/annuaire/regroupements/:regroupement_id',
				   { regroupement_id: '@regroupement_id' } );
	     } ] );

angular.module('cahierDeTexteApp')
  .factory('Users',
	   [ '$resource',
	     function( $resource ) {
		 return $resource( '/api/v0/annuaire/users/:user_id',
				   { user_id: '@user_id' } );
	     } ] );
