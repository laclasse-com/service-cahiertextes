'use strict';

angular.module('cahierDeTexteApp')
    .controller('EmploiDuTempsPopupDisplayCtrl',
		[ '$scope', '$sce', '$modalInstance', 'APP_PATH', 'DOCS_URL', 'Cours', 'Devoirs', 'titre', 'cours', 'devoirs',
		  function( $scope, $sce, $modalInstance, APP_PATH, DOCS_URL, Cours, Devoirs, titre, cours, devoirs ) {
		      $scope.app_path = APP_PATH;
		      $scope.titre = titre;
		      $scope.cours = Cours.get( { id: cours.id } );
		      $scope.devoirs = devoirs.map( function( devoir ) {
			  return Devoirs.get( { id: devoir.id } );
		      } );
		      _($scope.cours.ressources).each( function( ressource ) {
			  ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
		      } );
		      _($scope.devoirs).each( function( devoir ) {
			  _(devoir.ressources).each( function( ressource ) {
			      ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
			  } );
		      } );

		      $scope.tab_SP_active = $scope.devoirs.length == 0;

		      $scope.fait = function( id ) {
			  Devoirs.fait({ id: id });
		      };

		      $scope.fermer = function() {
			  $modalInstance.close( $scope );
		      };

		      $scope.cours.$promise.then( function( cours ) {
			  _(cours.devoirs).each( function( devoir ) {
			      devoir.tooltip = devoir.contenu;
			      if ( devoir.temps_estime > 0 ) {
				  devoir.tooltip = '<span><i class="picto temps"></i>' + devoir.temps_estime * 5 + ' minutes</span><hr>' + devoir.tooltip;
			      }
			  } );
		      } );
		  } ] );
