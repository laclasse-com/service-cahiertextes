'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .controller( 'IndexCtrl',
  [ '$scope', '$state', 'User',
    function( $scope, $state, User ) {
      var ctrl = $scope;

      User.get_user()
        .then( function( response ) {
          var user = response.data;

          switch ( user.profil_actif.type ) {
            case 'DIR':
              ctrl.tabs = [ {
                heading: 'Validation des saisies par enseignant',
                uisref: 'enseignants',
                css_class: 'glyphicon glyphicon-user',
                active: true
              },
              {
                heading: 'Emplois du Temps',
                uisref: 'emploi_du_temps',
                css_class: 'glyphicon glyphicon-calendar',
                active: false
              },
              {
                heading: 'Import Pronote',
                uisref: 'import',
                css_class: 'glyphicon glyphicon-import',
                active: false
              }];
              break;
            case 'ENS':
              ctrl.tabs = [ {
                heading: 'Cahier de textes',
                uisref: 'emploi_du_temps',
                css_class: 'glyphicon glyphicon-calendar',
                active: true
              },
              {
                heading: 'Statistiques',
                uisref: 'stats',
                css_class: 'glyphicon glyphicon-stats',
                active: false
              }];
              break;
            case 'TUT':
            case 'ELV':
              ctrl.tabs = [ {
                heading: 'Emploi du temps',
                uisref: 'emploi_du_temps',
                css_class: 'glyphicon glyphicon-calendar',
                active: true
              },
              {
                heading: 'Liste des devoirs',
                uisref: 'devoirs',
                css_class: 'glyphicon glyphicon-list',
                active: false
              }];
              break;
            case 'ADM':
              ctrl.tabs = [ {
                heading: 'Emplois du Temps',
                uisref: 'emploi_du_temps',
                css_class: 'glyphicon glyphicon-calendar',
                active: true
              },
              {
                heading: 'Import Pronote',
                uisref: 'import',
                css_class: 'glyphicon glyphicon-import',
                active: false
              }];
              break;
            case 'EVS':
              ctrl.tabs = [ {
                heading: 'Emplois du Temps',
                uisref: 'emploi_du_temps',
                css_class: 'glyphicon glyphicon-calendar',
                active: true
              }];
              break;
            default:
              ctrl.tabs = [];
          }

          _( ctrl.tabs ).each( function( tab ) {
            tab.active = tab.uisref == $state.current.name;
          } );

          ctrl.set_active_tab = function( uisref ) {
            _( ctrl.tabs ).each( function( tab ) {
              tab.active = tab.uisref == uisref;
            } );
          };

          ctrl.set_active_tab( ctrl.tabs[ 0 ].uisref );
          $state.go( ctrl.tabs[ 0 ].uisref );
        } );
    }] );
