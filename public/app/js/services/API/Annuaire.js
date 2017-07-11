'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .service('Annuaire',
             [ '$http', 'URL_ENT',
               function( $http, URL_ENT ) {
                   var service = this;

                   service.query_subjects = _.memoize( function(  ) {
                       return $http.get( URL_ENT + '/api/subjects' );
                   });

                   service.get_subject = _.memoize( function( matiere_id ) {
                       return $http.get( URL_ENT + '/api/subjects/' + matiere_id );
                   });

                   service.get_subjects = _.memoize( function( subjects_ids ) {
                       return $http.get( URL_ENT + '/api/subjects/', { params: { 'id[]': subjects_ids } } );
                   });

                   service.get_structure = _.memoize( function( uai ) {
                       return $http.get( URL_ENT + '/api/structures/' + uai );
                   });

                   service.get_group = _.memoize( function( group_id ) {
                       return $http.get( URL_ENT + '/api/groups/' + group_id );
                   });

                   service.get_groups = _.memoize( function( groups_ids ) {
                       return $http.get( URL_ENT + '/api/groups/', { params: { 'id[]': groups_ids } } );
                   });

                   service.get_groups_of_structures = _.memoize( function( structures_ids ) {
                       return $http.get( URL_ENT + '/api/groups/', { params: { 'structure_id[]': structures_ids } } );
                   });

                   service.get_user = _.memoize( function( user_id ) {
                       return $http.get( URL_ENT + '/api/users/' + user_id )
                           .then( function( response ) {
                               response.data.profil_actif = _(response.data.profiles).findWhere( { active: true } );

                               service.get_groups( _(response.data.groups).pluck('group_id') )
                                   .then( function( groups ) {
                                       response.data.groups.forEach( function( group ) {
                                           group.group = _(groups.data).findWhere({id: group.group_id });
                                       } );
                                   } );
                               service.get_subjects( _.chain(response.data.groups).pluck('subject_id').uniq().value() )
                                   .then( function( subjects ) {
                                       response.data.groups.forEach( function( group ) {
                                           group.subject = _(subjects.data).findWhere({id: group.subject_id });
                                       } );
                                   } );

                               return response;
                           } );
                   });

                   service.get_users = _.memoize( function( users_ids ) {
                       return $http.get( URL_ENT + '/api/users/', { params: { 'id[]': users_ids } } );
                   });
               }
             ] );
