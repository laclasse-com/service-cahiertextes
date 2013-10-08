'use strict';

angular.module('cahierDeTexteApp')
  .factory('APIMatieres',
	   [ '$resource',
	     function( $resource ) {
		 return $resource( 'http://www.dev.laclasse.com/api/app/matieres/:matiere_id',
				   { matiere_id: '@matiere_id' } );
	     } ] );

angular.module('cahierDeTexteApp')
  .factory('APIRegroupements',
	   [ '$resource',
	     function( $resource ) {
		 return $resource( 'http://www.dev.laclasse.com/api/app/regroupements/:regroupement_id',
				   { regroupement_id: '@regroupement_id' } );
	     } ] );

angular.module('cahierDeTexteApp')
  .factory('APIUsers',
	   [ '$resource',
	     function( $resource ) {
		 return $resource( 'http://www.dev.laclasse.com/api/app/users/:user_id?expand=true',
				   { user_id: '@user_id' } );
	     } ] );
