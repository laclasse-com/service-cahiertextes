'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveDevoirsCtrl',
		[ '$scope', '$modal', 'APP_PATH', 'API', 'Annuaire', 'Devoirs', 'Cours', 'CreneauEmploiDuTemps',
		  function( $scope, $modal, APP_PATH, API, Annuaire, Devoirs, Cours, CreneauEmploiDuTemps ) {
		      // popup d'affichage des détails
		      $scope.ouvre_popup_details = function( titre, cours, devoirs ) {
			  $modal.open( { templateUrl: APP_PATH + 'app/views/eleve/detail_emploi_du_temps.html',
					 controller: 'EmploiDuTempsPopupDisplayCtrl',
					 resolve: { titre  : function() { return titre; },
						    cours  : function() { return cours; },
						    devoirs: function() { return devoirs; } } }
				     );
		      };

		      $scope.empty = false;

		      $scope.affiche_faits = false;
		      $scope.fait = function( id ) {
			  Devoirs.fait({ id: id });
		      };

		      $scope.filtre = function() {
			  if ( ! $scope.affiche_faits ) {
			      $scope.devoirs = _($scope.all_devoirs).reject(function( devoir ) {
				  return devoir.fait;
			      });
			  } else {
			      $scope.devoirs = $scope.all_devoirs;
			  }
		      };

		      API.query_types_de_devoir()
			  .$promise.then( function( types_de_devoir ) {
			      API.query_devoirs()
				  .$promise.then(function( response ) {
				      $scope.all_devoirs = _(response).map( function( devoir ) {
					  devoir.type_devoir = _(types_de_devoir)
					      .findWhere({id: devoir.type_devoir_id});
					  devoir.creneau_emploi_du_temps = CreneauEmploiDuTemps.get({ id: devoir.creneau_emploi_du_temps_id });
					  devoir.creneau_emploi_du_temps.$promise.then( function success(  ) {
					      devoir.matiere = Annuaire.get_matiere( devoir.creneau_emploi_du_temps.matiere_id );
					  });
					  devoir.cours = Cours.get({ id: devoir.cours_id });
					  return devoir;
				      });
				      $scope.filtre();

				      $scope.empty = $scope.all_devoirs.length == 0;
				  });
			  });
		  } ] );
