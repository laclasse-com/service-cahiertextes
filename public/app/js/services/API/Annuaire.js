'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .service('Annuaire',
             [ '$http', '$q', 'URL_ENT',
               function( $http, $q, URL_ENT ) {
                   var service = this;
                   var beautify_group_type = function( type ) {
                       switch( type ) {
                       case 'CLS': return 'Classe';
                       case 'GRP': return 'Groupe';
                       case 'GPL': return 'Groupe libre';
                       default: return '';
                       }
                   };

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
                       return $http.get( URL_ENT + '/api/groups/' + group_id )
                           .then( function success( response ) {
                               response.data.full_type = beautify_group_type( response.data.type );

                               return $q.resolve( response );
                           } );
                   });

                   service.get_groups = _.memoize( function( groups_ids ) {
                       return $http.get( URL_ENT + '/api/groups/', { params: { 'id[]': groups_ids } } )
                           .then( function success( response ) {
                               response.data = response.data.map( function( group ) {
                                   group.full_type = beautify_group_type( group.type );

                                   return group;
                               } );

                               return $q.resolve( response );
                           } );
                   });

                   service.get_groups_of_structures = _.memoize( function( structures_ids ) {
                       return $http.get( URL_ENT + '/api/groups/', { params: { 'structure_id[]': structures_ids } } )
                           .then( function success( response ) {
                               response.data = response.data.map( function( group ) {
                                   group.full_type = beautify_group_type( group.type );

                                   return group;
                               } );

                               return $q.resolve( response );
                           } );
                   });

                   service.get_user = _.memoize( function( user_id ) {
                       return $http.get( URL_ENT + '/api/users/' + user_id )
                           .then( function( response ) {
                               response.data.profil_actif = _(response.data.profiles).findWhere( { active: true } );

                               response.data.get_actual_groups = function() {
                                   return service.get_groups( _(response.data.groups).pluck('group_id') )
                                       .then( function( groups ) {
                                           return $q.resolve( groups.data );
                                       } );
                               };

                               response.data.get_actual_subjects = function() {
                                   return service.get_subjects( _(response.data.groups).pluck('subject_id') )
                                       .then( function( subjects ) {
                                           return $q.resolve( subjects.data );
                                       } );
                               };

                               return response;
                           } );
                   });

                   service.get_users = _.memoize( function( users_ids ) {
                       return $http.get( URL_ENT + '/api/users/', { params: { 'id[]': users_ids } } );
                   });
               }
             ] );
