'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .factory('Regroupements',
             [ '$resource', 'URL_ENT',
               function( $resource, URL_ENT ) {
                   return $resource( URL_ENT + '/api/app/regroupements/:regroupement_id',
                                     { regroupement_id: '@regroupement_id' } );
               } ] )
    .factory('Users',
             [ '$resource', 'URL_ENT',
               function( $resource, URL_ENT ) {
                   return $resource( URL_ENT + '/api/app/users/:user_id',
                                     { user_id: '@user_id' },
                                     { bulk: { method: 'GET',
                                               url: URL_ENT + '/api/app/users/liste/:uids',
                                               params: { uids: '@uids' },
                                               isArray: true }
                                     } );
               } ] );

angular.module( 'cahierDeTextesClientApp' )
    .service('Annuaire',
             [ '$http', 'Regroupements', 'Users', 'URL_ENT',
               function( $http, Regroupements, Users, URL_ENT ) {
                   this.get_matieres = _.memoize( function(  ) {
                       return $http.get( URL_ENT + '/api/app/matieres' );
                   });

                   this.get_matiere = _.memoize( function( matiere_id ) {
                       return $http.get( URL_ENT + '/api/app/matieres/' + matiere_id );
                   });

                   this.get_etablissement = _.memoize( function( uai ) {
                       return $http.get( URL_ENT + '/api/app/v2/etablissements/' + uai );
                   });

                   this.get_etablissement_enseignants = _.memoize( function( uai ) {
                       return $http.get( URL_ENT + '/api/app/etablissements/' + uai + '/enseignants' );
                   });

                   this.get_etablissement_regroupements = _.memoize( function( uai ) {
                       return $http.get( URL_ENT + '/api/app/etablissements/' + uai + '/regroupements' );
                   });

                   this.get_regroupement = _.memoize( function( regroupement_id ) {
                       return Regroupements.get({ regroupement_id: regroupement_id });
                   });

                   this.get_user = _.memoize( function( user_id ) {
                       return Users.get({ user_id: user_id });
                   });

                   this.get_users_bulk = _.memoize( function( uids ) {
                       return Users.bulk({ uids: uids.join('_') });
                   });
               }
             ] );
