'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .service( 'Redirection',
              [ '$state', 'User',
                function( $state, User ) {
                    this.doorman = function( allowed_types ) {
                        User.get_user().then( function( response ) {
                            if (_(allowed_types).size() === 0
                                || ( _(allowed_types).indexOf( response.data.profil_actif.type ) === -1
                                     && !( response.data.profil_actif.admin )
                                   )
                               ) {
                                // traiter le raffraichissement de l'app en fonction du changement de profil actif
                                var stateName = '404';

                                switch ( response.data.profil_actif.type ) {
                                case 'DIR':
                                    stateName = 'principal.enseignants';
                                    break;
                                case 'ADM':
                                    stateName = 'adm.emploi_du_temps';
                                    break;
                                case 'EVS':
                                    stateName = 'vie_scolaire.emploi_du_temps';
                                    break;
                                case 'ENS':
                                case 'DOC':
                                    stateName = 'enseignant.emploi_du_temps';
                                    break;
                                case 'TUT':
                                case 'ELV':
                                    stateName = 'eleve.emploi_du_temps';
                                    break;
                                }
                                $state.go( stateName, $state.params, { reload: true, inherit: true, notify: true } );
                            }
                        } );
                    };
              }
            ] );
