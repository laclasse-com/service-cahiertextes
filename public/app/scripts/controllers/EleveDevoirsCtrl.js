'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveDevoirsCtrl',
		[ '$scope', '$sce', 'APP_PATH', 'DOCS_URL', 'API', 'Annuaire', 'PopupsCreneau', 'Devoirs', 'Cours', 'CreneauEmploiDuTemps', 'User',
		  function( $scope, $sce, APP_PATH, DOCS_URL, API, Annuaire, PopupsCreneau, Devoirs, Cours, CreneauEmploiDuTemps, User ) {
		      // popup d'affichage des détails
		      var types_de_devoir = [];
		      $scope.affiche_faits = false;
		      $scope.popup_ouverte = false;
		      $scope.popup_callback = function() {};
		      $scope.ouvre_popup_details = PopupsCreneau.display;
		      $scope.fait = function( id ) {
			  Devoirs.fait({ id: id });
		      };

		      User.get_user().then( function( response ) {
			  $scope.current_user = response.data;
		      } );

		      API.query_types_de_devoir()
			  .$promise.then( function( response ) {
			      types_de_devoir = response;

			      var retrieve_data = function() {
				  $scope.from_date = moment().subtract( $scope.month_offset, 'months' ).subtract( 15, 'days' ).toDate();
				  $scope.to_date = moment().subtract( $scope.month_offset, 'months' ).add( 15, 'days' ).toDate();

				  API.query_devoirs({ debut: $scope.from_date,
						      fin: $scope.to_date,
						      uid: $scope.current_user.profil_actif.type == 'TUT' ? $scope.current_user.enfant_actif.enfant.id_ent : null })
				      .$promise.then(function( response ) {
					  $scope.devoirs = _(response).map( function( devoir ) {
					      devoir.type_devoir = _(types_de_devoir).findWhere({id: devoir.type_devoir_id});
					      CreneauEmploiDuTemps.get({ id: devoir.creneau_emploi_du_temps_id })
						  .$promise.then( function success( response ) {
						      devoir.creneau_emploi_du_temps = response;
						      devoir.matiere = Annuaire.get_matiere( devoir.creneau_emploi_du_temps.matiere_id );
						  });
					      devoir.cours = _(devoir.cours_id).isNull() ? null : Cours.get({ id: devoir.cours_id });
					      _(devoir.ressources).each( function( ressource ) {
						  ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
					      } );

					      return devoir;
					  });
				      });
			      };

			      $scope.month_offset = 0;

			      // retrieve_data() when the value of week_offset changes
			      // n.b.: triggered when month_offset is initialized above
			      $scope.$watch( 'month_offset', function() {
				  retrieve_data();
			      } );

			      $scope.incr_offset = function() {
				  $scope.month_offset++;
			      };
			      $scope.decr_offset = function() {
				  $scope.month_offset--;
			      };
			      $scope.reset_offset = function() {
				  $scope.month_offset = 0;
			      };
			  });
		  } ] );
