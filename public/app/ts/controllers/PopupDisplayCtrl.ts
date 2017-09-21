'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .controller( 'PopupDisplayCtrl',
  [ '$scope', '$sce', '$uibModalInstance', 'toastr', 'APP_PATH', 'Cours', 'Devoirs', 'User',
    'titre', 'cours', 'devoirs',
    function( $scope, $sce, $uibModalInstance, toastr, APP_PATH, Cours, Devoirs, User,
      matiere, cours, devoirs ) {
      $scope.app_path = APP_PATH;
      $scope.matiere = matiere;
      $scope.date = null;

      if ( !_( cours ).isNull() ) {
        $scope.cours = new Cours( cours );

        $scope.date = $scope.cours.date_cours;
        _( cours.devoirs ).each( function( devoir ) {
          devoir.tooltip = devoir.contenu;
          if ( devoir.temps_estime > 0 ) {
            devoir.tooltip = `<span><i class="picto temps"></i>${ devoir.temps_estime * 5 } minutes</span><hr>${ devoir.tooltip }`;
          }
          devoir.tooltip = $sce.trustAsHtml( devoir.tooltip );
        } );
      }

      $scope.devoirs = devoirs.map( function( devoir ) {
        devoir.matiere = matiere;
        return new Devoirs( devoir );
      } );

      if ( _( $scope.date ).isNull() && !_( $scope.devoirs ).isEmpty() ) {
        $scope.date = $scope.devoirs[ 0 ].date_due;
      }

      $scope.fermer = function() {
        $uibModalInstance.close( $scope );
      };

      User.get_user().then( function( response ) {
        $scope.current_user = response.data;
      } );
    }] );
