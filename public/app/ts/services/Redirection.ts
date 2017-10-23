'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .service( 'Redirection',
  [ '$state', 'CurrentUser',
    function( $state, CurrentUser ) {
      this.doorman = function( allowed_types ) {
        CurrentUser.get().then( function( response ) {
          if ( _( allowed_types ).size() === 0
            || ( _( allowed_types ).indexOf( response.data.profil_actif.type ) === -1
              && !( response.data.profil_actif.admin )
            )
          ) {
            // traiter le raffraichissement de l'app en fonction du changement de profil actif
            let stateName = '404';

            switch ( response.data.profil_actif.type ) {
              case 'DIR':
                stateName = 'enseignants';
                break;
              case 'ADM':
              case 'EVS':
              case 'ENS':
              case 'DOC':
              case 'TUT':
              case 'ELV':
                stateName = 'emploi_du_temps';
                break;
            }
            $state.go( stateName, $state.params, { reload: true, inherit: true, notify: true } );
          }
        } );
      };
    }
  ] );
