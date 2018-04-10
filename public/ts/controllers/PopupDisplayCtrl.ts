'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .controller( 'PopupDisplayCtrl',
  [ '$scope', '$sce', '$uibModalInstance', 'toastr', 'APP_PATH', 'Cours', 'Devoirs', 'CurrentUser',
    'matiere', 'cours', 'devoirs',
    function( $scope, $sce, $uibModalInstance, toastr, APP_PATH, Cours, Devoirs, CurrentUser,
              matiere, cours, devoirs ) {
      let ctrl = $scope;
      ctrl.$ctrl = ctrl;

      ctrl.app_path = APP_PATH;
      ctrl.matiere = matiere;
      ctrl.date = null;

      if ( !_( cours ).isNull() ) {
        ctrl.cours = new Cours( cours );

        ctrl.date = ctrl.cours.date_cours;
        _( cours.devoirs ).each( function( devoir ) {
          devoir.tooltip = devoir.contenu;
          if ( devoir.temps_estime > 0 ) {
            devoir.tooltip = `<span><i class="picto temps"></i>${ devoir.temps_estime * 5 } minutes</span><hr>${ devoir.tooltip }`;
          }
          devoir.tooltip = $sce.trustAsHtml( devoir.tooltip );
        } );
      }

      ctrl.devoirs = devoirs.map( function( devoir ) {
        devoir.matiere = matiere;
        return new Devoirs( devoir );
      } );

      if ( _( ctrl.date ).isNull() && !_( ctrl.devoirs ).isEmpty() ) {
        ctrl.date = ctrl.devoirs[ 0 ].date_due;
      }

      ctrl.fermer = function() {
        $uibModalInstance.close( ctrl );
      };

      ctrl.default_active_tab = ctrl.devoirs.length > 0 ? 0 : 1;

      CurrentUser.get().then( function( response ) {
        ctrl.current_user = response;
      } );
    }] );
