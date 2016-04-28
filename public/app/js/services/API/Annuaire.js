'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .factory('Matieres',
             [ '$resource', 'APP_PATH', 'API_VERSION',
               function( $resource, APP_PATH, API_VERSION ) {
                   return $resource( APP_PATH + '/api/' + API_VERSION + '/annuaire/matieres/:matiere_id',
                                     { matiere_id: '@matiere_id' } );
               } ] );

angular.module( 'cahierDeTextesClientApp' )
    .factory('Regroupements',
             [ '$resource', 'APP_PATH', 'API_VERSION',
               function( $resource, APP_PATH, API_VERSION ) {
                   return $resource( APP_PATH + '/api/' + API_VERSION + '/annuaire/regroupements/:regroupement_id',
                                     { regroupement_id: '@regroupement_id' } );
               } ] );

angular.module( 'cahierDeTextesClientApp' )
    .factory('Users',
             [ '$resource', 'APP_PATH', 'API_VERSION',
               function( $resource, APP_PATH, API_VERSION ) {
                   return $resource( APP_PATH + '/api/' + API_VERSION + '/annuaire/users/:user_id',
                                     { user_id: '@user_id' },
                                     { bulk: { method: 'GET',
                                               url: APP_PATH + '/api/' + API_VERSION + '/annuaire/users/bulk/:uids',
                                               params: { uids: '@uids' },
                                               isArray: true }
                                     } );
               } ] );

angular.module( 'cahierDeTextesClientApp' )
    .service('Annuaire',
             [ '$http', 'Matieres', 'Regroupements', 'Users', 'APP_PATH', 'API_VERSION',
               function( $http, Matieres, Regroupements, Users, APP_PATH, API_VERSION ) {
                   this.get_matieres = _.memoize( function(  ) {
                       return $http.get( APP_PATH + '/api/' + API_VERSION + '/annuaire/matieres' );
                   });

                   this.get_etablissement = _.memoize( function( uai ) {
                       return $http.get( APP_PATH + '/api/' + API_VERSION + '/annuaire/etablissements/' + uai );
                   });

                   this.get_etablissement_enseignants = _.memoize( function( uai ) {
                       return $http.get( APP_PATH + '/api/' + API_VERSION + '/annuaire/etablissements/' + uai + '/enseignants' );
                   });

                   this.get_etablissement_regroupements = _.memoize( function( uai ) {
                       return $http.get( APP_PATH + '/api/' + API_VERSION + '/annuaire/etablissements/' + uai + '/regroupements' );
                   });

                   this.get_matiere = _.memoize( function( matiere_id ) {
                       return Matieres.get({ matiere_id: matiere_id });
                   });

                   this.get_regroupement = _.memoize( function( regroupement_id ) {
                       return Regroupements.get({ regroupement_id: regroupement_id });
                   });

                   this.get_user = _.memoize( function( user_id ) {
                       return Users.get({ user_id: user_id });
                   });

                   this.get_users_bulk = _.memoize( function( uids ) {
                       return Users.bulk({ uids: uids });
                   });
               }
             ] );
