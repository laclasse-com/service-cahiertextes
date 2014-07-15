'use strict';

angular.module('cahierDeTexteApp')
    .controller('EmploiDuTempsPopupDisplayCtrl',
		[ '$scope', '$modalInstance', 'Devoirs', 'titre', 'cours', 'devoirs',
  function( $scope, $modalInstance, Devoirs, titre, cours, devoirs ) {
      $scope.titre = titre;
      $scope.cours = cours;
      $scope.devoirs = devoirs;

      $scope.groups = { sequence_pedagogique: { ouvert: false },
			devoirs: { ouvert: true } };

      $scope.fait = function( id ) {
	  Devoirs.fait({ id: id });
      };

      $scope.fermer = function() {
	  $modalInstance.close( $scope );
      };
  } ] );
