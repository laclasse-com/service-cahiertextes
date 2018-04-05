'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .service( 'log',
  [ '$http', '$state', 'APP_PATH', 'CurrentUser', 'URL_ENT',
    function( $http, $state, APP_PATH, CurrentUser, URL_ENT ) {
      this.add = function( app, url, params ) {
        CurrentUser.get()
          .then( function( response ) {
            $http.post( `${ URL_ENT }/api/logs`,
                        {
                application_id: app,
              user_id: response.id,
              structure_id: response.profil_actif.structure_id,
              profil_id: response.profil_actif.type,
              url: ( _( url ).isNull() ? APP_PATH + $state.current.url : url ).substr( 0, 1023 ),
              params: _( params ).isNull() ? _( $state.params ).map( function( value, key ) { return `${ key }=${ value }`; } ).join( '&' ) : params
              } )
              .then( function success() { }, function error() { } );
          } );
      };
    }
  ] );
