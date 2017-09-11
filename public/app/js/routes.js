'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .config( [ '$stateProvider', '$urlRouterProvider',
               function ( $stateProvider, $urlRouterProvider ) {
                   $urlRouterProvider.otherwise('/');

                   $stateProvider
                   // 404 /////////////////////////////////////////////////////////////////
                       .state('404', {
                           url: '404',
                           templateUrl: 'views/404.html'
                       })
                   // index ///////////////////////////////////////////////////////////////
                       .state( 'index',
                               { url: '/',
                                 templateUrl: 'views/index.html',
                                 controller: 'IndexCtrl',
                                 resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'ADM', 'DIR', 'ENS', 'DOC', 'ELV', 'TUT', 'EVS' ] ); } ],
                                            current_user: [ 'User', function( User ) { return User.get_user().then( function( response ) { return response.data; } ); } ] } } )
                       .state( 'emploi_du_temps',
                               { parent: 'index',
                                 url: 'emploi_du_temps',
                                 views: {  'content': { templateUrl: 'views/textbook.html',
                                                        controller: 'TextBookCtrl' } } } )
                       .state( 'devoirs',
                               { parent: 'index',
                                 url: 'devoirs',
                                 resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'ELV', 'TUT' ] ); } ] },
                                 views: { 'content': { templateUrl: 'views/assignements.html',
                                                       controller: 'AssignementsCtrl' } } } )
                       .state( 'import',
                               { parent: 'index',
                                 url: 'import',
                                 resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'DIR', 'ADM' ] ); } ] },
                                 views: { 'content': { templateUrl: 'views/import.html',
                                                       controller: 'ImportCtrl' } } } )
                       .state( 'enseignants',
                               { parent: 'index',
                                 url: 'enseignants',
                                 resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } ] },
                                 views: { 'content': { templateUrl: 'views/dashboard_teachers.html',
                                                       controller: 'DashboardTeachersCtrl' } } } )
                       .state( 'enseignant',
                               { parent: 'index',
                                 url: 'enseignants/:enseignant_id',
                                 resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } ] },
                                 views: { 'content': { templateUrl: 'views/dashboard_teacher.html',
                                                       controller: 'DashboardTeacherCtrl' } } } )
                       .state( 'stats',
                               { parent: 'index',
                                 url: 'stats',
                                 resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'ENS', 'DOC' ] ); } ] },
                                 views: { 'content': { templateUrl: 'views/dashboard_teacher.html',
                                                       controller: 'DashboardTeacherCtrl' } } } );
               } ] )
    .run( [ '$rootScope', 'log',
            function( $rootScope, log ) {
                $rootScope.$on( '$stateChangeSuccess',
                                function( event, toState, toParams, fromState, fromParams ) {
                                    log.add( 'CTXT', null, null );
                                } );
            }
          ] );
