'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .service('User',
             [ '$http', 'APP_PATH', 'API_VERSION',
               function( $http, APP_PATH, API_VERSION ) {
                   this.get_user = _.memoize( function() {
                       return $http.get( APP_PATH + '/api/' + API_VERSION + '/users/current' )
                           .success( function( response ) {
                               _(response.profils).each( function( profil ) {
                                   // Liste des regroupements liées au profil
                                   profil.regroupements = _.chain(response.regroupements)
                                       .filter( function( classe ) { return classe.etablissement_code == profil.etablissement_code_uai; } )
                                       .map( function( classe ) {
                                           return { id: classe.id,
                                                    libelle: classe.libelle,
                                                    type: classe.type };
                                       } )
                                       .uniq( function( item ) { return item.id; } )
                                       .reject( function( item ) { return _.isUndefined( item.id ); } )
                                       .value();
                               } );
                               response.profil_actif = _(response.profils).findWhere( { actif: true } );

                               if ( response.enfants.length > 0 ) {
                                   response.enfant_actif = response.enfants[ 0 ];
                               }

                               // Voir quel est le profil
                               response.is = function( profil_id ) {
                                   return this.profil_actif['profil_id'] == profil_id;
                               };

                               return response;
                           } );
                   } );

                   this.update_parameters = function( parametres ) {
                       return $http.put( APP_PATH + '/api/' + API_VERSION + '/users/current/parametres',
                                         { parametres: JSON.stringify( parametres ) } );
                   };
               } ] );

angular.module( 'cahierDeTextesClientApp' )
    .factory('Classes', [ '$resource', 'APP_PATH', 'API_VERSION',
                          function( $resource, APP_PATH, API_VERSION ) {
                              return $resource( APP_PATH + '/api/' + API_VERSION + '/etablissements/:uai/statistiques/classes/:id',
                                                { uai: '@uai',
                                                  id: '@id' } );
                          } ] );

angular.module( 'cahierDeTextesClientApp' )
    .factory('Cours',
             [ '$resource', 'APP_PATH', 'API_VERSION',
               function( $resource, APP_PATH, API_VERSION ) {
                   return $resource( APP_PATH + '/api/' + API_VERSION + '/cours/:id',
                                     { id: '@id' },
                                     { update: { method: 'PUT' },
                                       valide: { method: 'PUT',
                                                 url: APP_PATH + '/api/' + API_VERSION + '/cours/:id/valide' },
                                       copie: { method: 'PUT',
                                                url: APP_PATH + '/api/' + API_VERSION + '/cours/:id/copie/regroupement/:regroupement_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date/:date',
                                                params: { id: '@id',
                                                          regroupement_id: '@regroupement_id',
                                                          creneau_emploi_du_temps_id: '@creneau_emploi_du_temps_id',
                                                          date: '@date' } } } );
               } ] );

angular.module( 'cahierDeTextesClientApp' )
    .factory('CreneauEmploiDuTemps',
             [ '$resource', 'APP_PATH', 'API_VERSION',
               function( $resource, APP_PATH, API_VERSION ) {
                   return $resource( APP_PATH + '/api/' + API_VERSION + '/creneaux_emploi_du_temps/:id',
                                     { id: '@id',
                                       regroupement_id: '@regroupement_id',
                                       previous_regroupement_id: '@previous_regroupement_id',
                                       jour_de_la_semaine: '@jour_de_la_semaine',
                                       heure_debut: '@heure_debut',
                                       heure_fin: '@heure_fin',
                                       matiere_id: '@matiere_id',
                                       semaines_de_presence_regroupement: '@semaines_de_presence_regroupement',
                                       semaines_de_presence_enseignant: '@semaines_de_presence_enseignant',
                                       semaines_de_presence_salle: '@semaines_de_presence_salle' },
                                     { update: { method: 'PUT' },
                                       delete: { method: 'DELETE',
                                                 params: { id: '@id',
                                                           date_creneau: '@date_creneau' } } } );
               } ] );

angular.module( 'cahierDeTextesClientApp' )
    .factory('Devoirs',
             [ '$resource', 'APP_PATH', 'API_VERSION',
               function( $resource, APP_PATH, API_VERSION ) {
                   return $resource( APP_PATH + '/api/' + API_VERSION + '/devoirs/:id',
                                     { id: '@id',
                                       uid: '@uid'},
                                     { update: { method: 'PUT' },
                                       fait: { method: 'PUT',
                                               url: APP_PATH + '/api/' + API_VERSION + '/devoirs/:id/fait' },
                                       copie: { method: 'PUT',
                                                url: APP_PATH + '/api/' + API_VERSION + '/devoirs/:id/copie/cours/:cours_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date_due/:date_due',
                                                params: { id: '@id',
                                                          cours_id: '@cours_id',
                                                          creneau_emploi_du_temps_id: '@creneau_emploi_du_temps_id',
                                                          date_due: '@date_due' } } } );
               } ] );

angular.module( 'cahierDeTextesClientApp' )
    .factory('EmploisDuTemps',
             [ '$resource', 'APP_PATH', 'API_VERSION',
               function( $resource, APP_PATH, API_VERSION ) {
                   return $resource( APP_PATH + '/api/' + API_VERSION + '/emplois_du_temps',
                                     { debut: '@debut',
                                       fin: '@fin',
                                       uid: '@uid' } );
               } ] );

angular.module( 'cahierDeTextesClientApp' )
    .factory('Enseignants',
             [ '$resource', 'APP_PATH', 'API_VERSION',
               function( $resource, APP_PATH, API_VERSION ) {
                   return $resource( APP_PATH + '/api/' + API_VERSION + '/etablissements/:uai/statistiques/enseignants/:enseignant_id',
                                     { uai: '@uai',
                                       enseignant_id: '@enseignant_id' } );
               } ] );

angular.module( 'cahierDeTextesClientApp' )
    .factory('TypesDeDevoir',
             [ '$resource', 'APP_PATH', 'API_VERSION',
               function( $resource, APP_PATH, API_VERSION ) {
                   return $resource( APP_PATH + '/api/' + API_VERSION + '/types_de_devoir/:id',
                                     { id: '@id' });
               } ] );

angular.module( 'cahierDeTextesClientApp' )
    .factory('PlagesHoraires',
             [ '$resource', 'APP_PATH', 'API_VERSION',
               function( $resource, APP_PATH, API_VERSION ) {
                   return $resource( APP_PATH + '/api/' + API_VERSION + '/plages_horaires/:id',
                                     { id: '@id' });
               } ] );

angular.module( 'cahierDeTextesClientApp' )
    .service('API',
             [ '$http', 'APP_PATH', 'API_VERSION', 'Classes', 'Cours', 'CreneauEmploiDuTemps', 'Devoirs', 'EmploisDuTemps', 'Enseignants', 'TypesDeDevoir', 'PlagesHoraires',
               function( $http, APP_PATH, API_VERSION, Classes, Cours, CreneauEmploiDuTemps, Devoirs, EmploisDuTemps, Enseignants, TypesDeDevoir, PlagesHoraires ) {
                   this.query_classes = function( params ) {
                       return Classes.query( params );
                   };

                   this.query_types_de_devoir = _.memoize( function() {
                       return TypesDeDevoir.query();
                   } );
                   this.get_type_de_devoir = _.memoize( function( params ) {
                       return TypesDeDevoir.get( params );
                   } );

                   this.query_emplois_du_temps = function() {
                       return EmploisDuTemps.query();
                   };

                   this.get_creneau_emploi_du_temps = function( params ) {
                       return CreneauEmploiDuTemps.get( params );
                   };
                   this.get_creneaux_emploi_du_temps_similaires = function( params ) {
                       return $http.get( APP_PATH + '/api/' + API_VERSION + '/creneaux_emploi_du_temps/' + params.id + '/similaires?debut=' + params.debut.toISOString() + '&fin=' + params.fin.toISOString() );
                   };

                   this.query_enseignants = function( params ) {
                       return Enseignants.query( params );
                   };
                   this.get_enseignant = function( params ) {
                       return Enseignants.get( params );
                   };

                   this.get_cours = function( params ) {
                       return Cours.get( params );
                   };

                   this.query_devoirs = function( params ) {
                       return Devoirs.query( params );
                   };
                   this.get_devoir = function( params ) {
                       return Devoirs.get( params );
                   };

                   this.query_plages_horaires = function() {
                       return PlagesHoraires.query();
                   };
                   this.get_plage_horaire = function( params ) {
                       return PlagesHoraires.get( params );
                   };
               }
             ] );
