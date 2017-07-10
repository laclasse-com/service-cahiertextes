angular.module( 'cahierDeTextesClientApp' )
    .service( 'log',
              [ '$http', '$state', 'APP_PATH', 'User',
                function( $http, $state, APP_PATH, User ) {
                    this.add = function( app, url, params ) {
                        User.get_user(  )
                            .then( function( response ) {
                                var user = response.data;
                                $http.post( '/api/log',
                                            { app: app,
                                              uid: user.uid,
                                              uai: user.profil_actif.structure_id,
                                              user_type: user.profil_actif.type,
                                              timestamp: Date.now(),
                                              url: ( _(url).isNull() ? APP_PATH + $state.current.url: url ).substr( 0, 1023 ),
                                              params: _(params).isNull() ? _($state.params).map( function( value, key ) { return key + '=' + value; } ).join( '&' ) : params } )
                                    .then( function success() {}, function error() {} );
                            } );
                    };
                }
              ] );
