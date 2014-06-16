'use strict';

angular.module('cahierDeTexteApp')
    .controller('PopupEmploiDuTempsDisplayCtrl',
		[ '$scope', '$modalInstance', 'Devoirs', 'titre', 'cours', 'devoirs',
  function( $scope, $modalInstance, Devoirs, titre, cours, devoirs ) {
      var scope_popup = $scope;
      scope_popup.titre = titre;
      scope_popup.cours = cours;
      scope_popup.devoirs = devoirs;

      scope_popup.fait = function( devoir_id ) {
	  Devoirs.fait({ id: devoir_id },
		       function() {
			   _(devoirs).findWhere({id: devoir_id}).fait = true;
		       });
      };

      scope_popup.fermer = function() {
	  $modalInstance.close( scope_popup );
      };
  } ] );
