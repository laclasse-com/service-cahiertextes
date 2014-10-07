'use strict';

angular.module('cahierDeTexteApp')
    .controller('EleveDevoirsCtrl',
		[ '$scope', '$sce', 'APP_PATH', 'DOCS_URL', 'API', 'Annuaire', 'Devoirs', 'Cours', 'CreneauEmploiDuTemps', 'current_user',
		  function( $scope, $sce, APP_PATH, DOCS_URL, API, Annuaire, Devoirs, Cours, CreneauEmploiDuTemps, current_user ) {
		      // popup d'affichage des détails
		      var types_de_devoir = [];
		      $scope.affiche_faits = false;
		      $scope.tri_ascendant = true;
		      $scope.popup_ouverte = false;
		      $scope.fait = function( id ) {
			  Devoirs.fait({ id: id });
		      };

		      $scope.current_user = current_user;

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
					  $scope.matieres = {};

					  $scope.all_devoirs = _(response).map( function( devoir ) {
					      devoir.type_devoir = _(types_de_devoir).findWhere({id: devoir.type_devoir_id});

					      CreneauEmploiDuTemps.get({ id: devoir.creneau_emploi_du_temps_id })
						  .$promise.then( function success( response ) {
						      devoir.creneau_emploi_du_temps = response;
						      $scope.matieres[ devoir.creneau_emploi_du_temps.matiere_id ] = Annuaire.get_matiere( devoir.creneau_emploi_du_temps.matiere_id );
						      devoir.matiere = $scope.matieres[ devoir.creneau_emploi_du_temps.matiere_id ];
						  });

					      devoir.cours = _(devoir.cours_id).isNull() ? null : Cours.get({ id: devoir.cours_id });

					      _(devoir.ressources).each( function( ressource ) {
						  ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
					      } );

					      return devoir;
					  });
					  $scope.devoirs = $scope.all_devoirs;
				      });
			      };

			      $scope.filter_data = function( matiere_id ) {
				  if ( _(matiere_id).isNull() ) {
				      $scope.devoirs = $scope.all_devoirs;
				  } else {
				      $scope.devoirs = _($scope.all_devoirs).select( function( devoir ) {
					  return devoir.creneau_emploi_du_temps.matiere_id == matiere_id;
				      } );
				  }
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