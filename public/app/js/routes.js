'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .config( [ '$stateProvider', '$urlRouterProvider',
               function ( $stateProvider, $urlRouterProvider ) {
                   $urlRouterProvider.otherwise('/');

                   $stateProvider
                   // 404 /////////////////////////////////////////////////////////////////
                       .state('404', {
                           url: '/404',
                           templateUrl: 'views/404.html'
                       })
                   // index ///////////////////////////////////////////////////////////////
                       .state('index', {
                           url: '/',
                           templateUrl: 'views/index.html',
                           controller: 'IndexCtrl',
                           resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'DIR', 'ENS', 'DOC', 'ELV', 'TUT', 'EVS' ] ); } ],
                                      current_user: [ 'User', function( User ) { return User.get_user().then( function( response ) { return response.data; } ); } ] }
                       })
                       .state('emploi_du_temps', {
                           parent: 'index',
                           url: '/emploi_du_temps/:date/:regroupements',
                           views: {
                               'content': {
                                   templateUrl: 'views/emploi_du_temps.html',
                                   controller: 'EmploiDuTempsCtrl'
                               }
                           }
                       })
                       .state('devoirs', {
                           parent: 'index',
                           url: '/devoirs/:from/:to/:matiere',
                           resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'ELV', 'TUT' ] ); } ] },
                           views: {
                               'content': {
                                   templateUrl: 'views/devoirs.html',
                                   controller: 'EleveDevoirsCtrl'
                               }
                           }
                       })
                       .state('import', {
                           parent: 'index',
                           url: '/import',
                           resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } ] },
                           views: {
                               'content': {
                                   controller: 'ImportCtrl',
                                   templateUrl: 'views/import.html'
                               }
                           }
                       })
                       .state('enseignants', {
                           parent: 'index',
                           url: '/enseignants',
                           resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } ] },
                           views: {
                               'content': {
                                   templateUrl: 'views/enseignants.html',
                                   controller: 'PrincipalEnseignantsCtrl'
                               }
                           }
                       })
                       .state('enseignant', {
                           parent: 'index',
                           url: '/enseignants/:enseignant_id',
                           resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'DIR' ] ); } ] },
                           views: {
                               'content': {
                                   templateUrl: 'views/stats_enseignant.html',
                                   controller: 'StatsEnseignantCtrl'
                               }
                           }
                       })
                       .state('stats', {
                           parent: 'index',
                           url: '/stats',
                           resolve: { auth: [ 'Redirection', function( Redirection ) { Redirection.doorman( [ 'ENS', 'DOC' ] ); } ] },
                           views: {
                               'content': {
                                   templateUrl: 'views/stats_enseignant.html',
                                   controller: 'StatsEnseignantCtrl'
                               }
                           }
                       });
               } ] )
    .run( [ '$rootScope', 'log',
            function( $rootScope, log ) {
                $rootScope.$on( '$stateChangeSuccess',
                                function( event, toState, toParams, fromState, fromParams ) {
                                    log.add( 'CTXT', null, null );
                                } );
            }
          ] );
