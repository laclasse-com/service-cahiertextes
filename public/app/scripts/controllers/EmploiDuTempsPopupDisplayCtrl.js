'use strict';

angular.module('cahierDeTexteApp')
    .controller('EmploiDuTempsPopupDisplayCtrl',
		[ '$scope', '$modalInstance', 'Devoirs', 'titre', 'cours', 'devoirs',
  function( $scope, $modalInstance, Devoirs, titre, cours, devoirs ) {
      var scope_popup = $scope;
      scope_popup.titre = titre;
      scope_popup.cours = cours;
      scope_popup.devoirs = devoirs;

      $scope.fait = function( id ) {
	  Devoirs.fait({ id: id },
		       function() {
			   var devoir = _($scope.devoirs).findWhere({ id: id });
			   devoir.fait = !devoir.fait;
		       });
      };

      scope_popup.fermer = function() {
	  $modalInstance.close( scope_popup );
      };
  } ] );
