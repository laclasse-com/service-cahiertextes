'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveDevoirsCtrl',
		[ '$scope', '$sce', 'APP_PATH', 'DOCS_URL', 'API', 'Annuaire', 'PopupsCreneau', 'Devoirs', 'Cours', 'CreneauEmploiDuTemps', 'User',
		  function( $scope, $sce, APP_PATH, DOCS_URL, API, Annuaire, PopupsCreneau, Devoirs, Cours, CreneauEmploiDuTemps, User ) {
		      // popup d'affichage des détails
		      $scope.popup_ouverte = false;
		      $scope.popup_callback = function() {};
		      $scope.ouvre_popup_details = PopupsCreneau.display;

		      $scope.empty = false;

		      $scope.affiche_faits = false;
		      $scope.fait = function( id ) {
			  Devoirs.fait({ id: id });
		      };

		      User.get_user().then( function( response ) {
			  $scope.current_user = response.data;
		      } );

		      API.query_types_de_devoir()
			  .$promise.then( function( types_de_devoir ) {
			      API.query_devoirs()
				  .$promise.then(function( response ) {
				      $scope.devoirs = _(response).map( function( devoir ) {
					  devoir.type_devoir = _(types_de_devoir).findWhere({id: devoir.type_devoir_id});
					  devoir.creneau_emploi_du_temps = CreneauEmploiDuTemps.get({ id: devoir.creneau_emploi_du_temps_id });
					  devoir.creneau_emploi_du_temps.$promise.then( function success(  ) {
					      devoir.matiere = Annuaire.get_matiere( devoir.creneau_emploi_du_temps.matiere_id );
					  });
					  devoir.cours = Cours.get({ id: devoir.cours_id });
					  _(devoir.ressources).each( function( ressource ) {
					      ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
					  } );

					  return devoir;
				      });

				      $scope.empty = $scope.devoirs.length == 0;
				  });
			  });
		  } ] );
