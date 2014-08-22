'use strict';

angular.module('cahierDeTexteApp')
    .controller('EmploiDuTempsPopupDisplayCtrl',
		[ '$scope', '$modalInstance', 'Devoirs', 'titre', 'cours', 'devoirs',
  function( $scope, $modalInstance, Devoirs, titre, cours, devoirs ) {
      $scope.titre = titre;
      $scope.cours = cours;
      $scope.devoirs = devoirs;
      $scope.tab_SP_active = $scope.devoirs.length == 0;

      $scope.fait = function( id ) {
	  Devoirs.fait({ id: id });
      };

      $scope.fermer = function() {
	  $modalInstance.close( $scope );
      };
  } ] );
