'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .service( 'User',
              [ '$http', '$q', 'APP_PATH', 'Annuaire',
                function( $http, $q, APP_PATH, Annuaire ) {
                    this.get_user = _.memoize( function() {
                        return $http.get( APP_PATH + '/api/users/current' )
                            .then( function( response ) {
                                _(response.data.profils).each( function( profil ) {
                                    // Liste des regroupements liées au profil
                                    profil.regroupements = _.chain(response.data.regroupements)
                                        .filter( function( classe ) { return classe.etablissement_code == profil.structure_id; } )
                                        .map( function( classe ) {
                                            return { id: classe.id,
                                                     libelle: classe.libelle,
                                                     type: classe.type };
                                        } )
                                        .uniq( function( item ) { return item.id; } )
                                        .reject( function( item ) { return _.isUndefined( item.id ); } )
                                        .value();
                                } );
                                response.data.profil_actif = _(response.data.profils).findWhere( { active: true } );

                                if ( response.data.enfants.length > 0 ) {
                                    response.data.enfant_actif = response.data.enfants[ 0 ];
                                }

                                response.data.get_actual_groups = function() {
                                    return Annuaire.get_groups( _.chain(response.data.groups).pluck( 'group_id' ).uniq().value() )
                                        .then( function( groups ) {
                                            response.data.actual_groups = _(groups.data).select( function( group ) {
                                                return group.structure_id === response.data.profil_actif.structure_id;
                                            } );

                                            return $q.resolve( response.data.actual_groups );
                                        } );
                                };

                                response.data.extract_subjects_ids = function() {
                                    return _.chain(response.data.groups).pluck('subject_id').uniq().value();
                                };

                                // Voir quel est le profil
                                response.data.is = function( type ) {
                                    return this.profil_actif.type == type;
                                };

                                return response;
                            } );
                    } );

                    this.update_parameters = function( parametres ) {
                        return $http.put( APP_PATH + '/api/users/current/parametres',
                                          { parametres: JSON.stringify( parametres ) } );
                    };
               } ] )

    .factory( 'StatistiquesRegroupements', [ '$resource', 'APP_PATH',
                                             function( $resource, APP_PATH ) {
                                                return $resource( APP_PATH + '/api/etablissements/:uai/statistiques/regroupements/:id',
                                                                  { uai: '@uai',
                                                                    id: '@id' } );
                                            } ] )

    .factory('Cours',
             [ '$resource', 'APP_PATH',
               function( $resource, APP_PATH ) {
                   return $resource( APP_PATH + '/api/cours/:id',
                                     { id: '@id' },
                                     { update: { method: 'PUT' },
                                       valide: { method: 'PUT',
                                                 url: APP_PATH + '/api/cours/:id/valide' },
                                       copie: { method: 'PUT',
                                                url: APP_PATH + '/api/cours/:id/copie/regroupement/:regroupement_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date/:date',
                                                params: { id: '@id',
                                                          regroupement_id: '@regroupement_id',
                                                          creneau_emploi_du_temps_id: '@creneau_emploi_du_temps_id',
                                                          date: '@date' } } } );
               } ] )

    .factory('CreneauxEmploiDuTemps',
             [ '$resource', 'APP_PATH',
               function( $resource, APP_PATH ) {
                   return $resource( APP_PATH + '/api/creneaux_emploi_du_temps/:id',
                                     { id: '@id',
                                       regroupement_id: '@regroupement_id',
                                       previous_regroupement_id: '@previous_regroupement_id',
                                       jour_de_la_semaine: '@jour_de_la_semaine',
                                       heure_debut: '@heure_debut',
                                       heure_fin: '@heure_fin',
                                       matiere_id: '@matiere_id',
                                       semainier_regroupement: '@semainier_regroupement',
                                       semainier_salle: '@semainier_salle' },
                                     { update: { method: 'PUT' },
                                       delete: { method: 'DELETE',
                                                 params: { id: '@id',
                                                           date_creneau: '@date_creneau' } },
                                       bulk: { method: 'POST',
                                               isArray: true,
                                               url: APP_PATH + '/api/creneaux_emploi_du_temps/bulk',
                                               params: { creneaux_emploi_du_temps: '@creneaux_emploi_du_temps' } },
                                       bulk_delete: { method: 'DELETE',
                                                      isArray: true,
                                                      url: APP_PATH + '/api/creneaux_emploi_du_temps/bulk',
                                                      params: { ids: '@ids',
                                                                date_creneau: '@date_creneau' } } } );
               } ] )

    .factory('Devoirs',
             [ '$resource', 'APP_PATH',
               function( $resource, APP_PATH ) {
                   return $resource( APP_PATH + '/api/devoirs/:id',
                                     { id: '@id',
                                       uid: '@uid'},
                                     { update: { method: 'PUT' },
                                       fait: { method: 'PUT',
                                               url: APP_PATH + '/api/devoirs/:id/fait' },
                                       copie: { method: 'PUT',
                                                url: APP_PATH + '/api/devoirs/:id/copie/cours/:cours_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date_due/:date_due',
                                                params: { id: '@id',
                                                          cours_id: '@cours_id',
                                                          creneau_emploi_du_temps_id: '@creneau_emploi_du_temps_id',
                                                          date_due: '@date_due' } } } );
               } ] )

    .factory('EmploisDuTemps',
             [ '$resource', 'APP_PATH',
               function( $resource, APP_PATH ) {
                   return $resource( APP_PATH + '/api/emplois_du_temps',
                                     { debut: '@debut',
                                       fin: '@fin',
                                       uid: '@uid' } );
               } ] )

    .factory('Enseignants',
             [ '$resource', 'APP_PATH',
               function( $resource, APP_PATH ) {
                   return $resource( APP_PATH + '/api/etablissements/:uai/statistiques/enseignants/:enseignant_id',
                                     { uai: '@uai',
                                       enseignant_id: '@enseignant_id' } );
               } ] )

    .factory('Etablissements',
             [ '$resource', 'APP_PATH',
               function( $resource, APP_PATH ) {
                   return $resource( APP_PATH + '/api/etablissements/:uai',
                                     { uai: '@uai' } );
               } ] )

    .factory('Salles',
             [ '$resource', 'APP_PATH',
               function( $resource, APP_PATH ) {
                   return $resource( APP_PATH + '/api/salles/:id',
                                     { id: '@id' },
                                     { bulk: { method: 'POST',
                                               isArray: true,
                                               url: APP_PATH + '/api/salles/bulk',
                                               params: { salles: '@salles' } } } );
               } ] )

    .factory('CahiersDeTextes',
             [ '$resource', 'APP_PATH',
               function( $resource, APP_PATH ) {
                   return $resource( APP_PATH + '/api/cahiers_de_textes/:id',
                                     { id: '@id' },
                                     { bulk: { method: 'POST',
                                               isArray: true,
                                               url: APP_PATH + '/api/cahiers_de_textes/bulk',
                                               params: { cahiers_de_textes: '@cahiers_de_textes' } } } );
               } ] )

    .factory('TypesDeDevoir',
             [ '$resource', 'APP_PATH',
               function( $resource, APP_PATH ) {
                   return $resource( APP_PATH + '/api/types_de_devoir/:id',
                                     { id: '@id' });
               } ] )

    .factory('Matchable',
             [ '$resource', 'APP_PATH',
               function( $resource, APP_PATH ) {
                   return $resource( APP_PATH + '/api/import/matchable/:uai/:hash_item',
                                     { uai: '@uai',
                                       hash_item: '@hash_item',
                                       id_annuaire: '@id_annuaire'});
               } ] );

angular.module( 'cahierDeTextesClientApp' )
    .service('API',
             [ '$http', 'APP_PATH', 'StatistiquesRegroupements', 'Cours', 'CreneauxEmploiDuTemps', 'Devoirs', 'EmploisDuTemps', 'Enseignants', 'Etablissements', 'TypesDeDevoir',
               function( $http, APP_PATH, StatistiquesRegroupements, Cours, CreneauxEmploiDuTemps, Devoirs, EmploisDuTemps, Enseignants, Etablissements, TypesDeDevoir ) {
                   this.get_etablissement = function( params ) {
                       return Etablissements.get( params );
                   };

                   this.query_statistiques_regroupements = function( params ) {
                       return StatistiquesRegroupements.query( params );
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
                       return CreneauxEmploiDuTemps.get( params );
                   };
                   this.get_creneaux_emploi_du_temps_similaires = function( params ) {
                       return $http.get( APP_PATH + '/api/creneaux_emploi_du_temps/' + params.id + '/similaires?debut=' + params.debut.toISOString() + '&fin=' + params.fin.toISOString() );
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
               }
             ] );
