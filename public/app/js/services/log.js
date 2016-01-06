angular.module( 'cahierDeTextesClientApp' )
    .service( 'log',
	      [ '$http', '$state', 'APP_PATH', 'User',
		function( $http, $state, APP_PATH, User ) {
		    this.add = function( app, url, params ) {
			User.get_user(  )
			    .then( function( response ) {
				var user = response.data;
				$http.post( APP_PATH + '/log',
					    { app: app,
					      uid: user.uid,
					      uai: user.profil_actif.etablissement_code_uai,
					      user_type: user.profil_actif.profil_id,
					      timestamp: Date.now(),
					      url: _(url).isNull() ? APP_PATH + $state.current.url: url,
					      params: _(params).isNull() ? _($state.params).map( function( value, key ) { return key + '=' + value; } ).join( '&' ) : params } );
			    } );
		    };
		}
	      ] );
