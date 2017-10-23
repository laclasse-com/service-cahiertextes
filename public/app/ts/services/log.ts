'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .service( 'log',
  [ '$http', '$state', 'APP_PATH', 'CurrentUser', 'URL_ENT',
    function( $http, $state, APP_PATH, CurrentUser, URL_ENT ) {
      this.add = function( app, url, params ) {
        CurrentUser.get()
          .then( function( response ) {
            let user = response.data;
            $http.post( `${ URL_ENT }/api/logs`,
              {
                application_id: app,
                user_id: user.id,
                structure_id: user.profil_actif.structure_id,
                profil_id: user.profil_actif.type,
                url: ( _( url ).isNull() ? APP_PATH + $state.current.url : url ).substr( 0, 1023 ),
                params: _( params ).isNull() ? _( $state.params ).map( function( value, key ) { return `${ key }=${ value }`; } ).join( '&' ) : params
              } )
              .then( function success() { }, function error() { } );
          } );
      };
    }
  ] );
