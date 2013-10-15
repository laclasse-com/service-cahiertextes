'use strict';

angular.module('cahierDeTexteApp')
  .factory('Matieres',
	   [ '$resource',
	     function( $resource ) {
		 return $resource( 'http://www.dev.laclasse.com/api/app/matieres/:matiere_id',
				   { matiere_id: '@matiere_id' } );
	     } ] );

angular.module('cahierDeTexteApp')
  .factory('Regroupements',
	   [ '$resource',
	     function( $resource ) {
		 return $resource( 'http://www.dev.laclasse.com/api/app/regroupements/:regroupement_id',
				   { regroupement_id: '@regroupement_id' } );
	     } ] );

angular.module('cahierDeTexteApp')
  .factory('Users',
	   [ '$resource',
	     function( $resource ) {
		 return $resource( 'http://www.dev.laclasse.com/api/app/users/:user_id?expand=true',
				   { user_id: '@user_id' } );
	     } ] );
