'use strict';

angular.module('cahierDeTexteApp')
    .controller('ListeCahierDeTextesCtrl',
		[ '$scope', '$modal', '$q', '$filter', 'API', 'Annuaire', 'EmploisDuTemps', 'User', 'CreneauEmploiDuTemps',
		  function ( $scope, $modal, $q, $filter, API, Annuaire, EmploisDuTemps, User, CreneauEmploiDuTemps ) {
		      var matieres = [];
		      var matieres_enseignees = [];
		      $scope.selected_regroupement_id = null;

		      $scope.creneau_selectionne = {};
		      // popup d'édition
		      var ouvre_popup_edition = function ( raw_data, matieres, classes, creneau_selectionne, cours, devoirs, popup_callback ) {
			  $modal.open( {
			      templateUrl: 'app/views/enseignant/edition_emploi_du_temps.html',
			      controller: 'EmploiDuTempsPopupEditionCtrl',
			      resolve: {
				  raw_data	     : function () { return raw_data; },
				  matieres	     : function () { return matieres; },
				  classes	     : function () { return classes; },
				  creneau_selectionne: function () { return creneau_selectionne; },
				  cours		     : function () { return cours; },
				  devoirs	     : function () { return devoirs; }
			      }
			  } )
			      .result.then( // éxécuté à la fermeture de la popup
				  function ( scope_popup ) {
				      // élimination des devoirs non finalisés
				      scope_popup.devoirs = _( scope_popup.devoirs )
					  .filter( function ( devoir ) {
					      return _( devoir )
						  .has( 'id' );
					  } );

				      // appel du callback
				      popup_callback( scope_popup );
				  } );
		      };

		      var filter_data = function( raw_data ) {
			  var filtered_data = _.chain(raw_data)
				  .filter( function( creneau ) {
				      return creneau.enseignant_id === $scope.current_user.uid;
				  } )
				  .filter( function( creneau ) {
				      return ! _(creneau.cours).isEmpty();
				  })
				  .uniq( function( creneau ) {
				      return creneau.creneau_emploi_du_temps_id;
				  })
				  .map( function( creneau ) {
				      creneau.devoirs.ouvert = false;
				      return creneau;
				  })
				  .value();

			  // Filtrage sur une seule classe
			  if ( ! _($scope.selected_regroupement_id).isNull() ) {
			      filtered_data = _( $scope.filtered_data ).filter( function( creneau ) {
				  return creneau.regroupement_id == $scope.selected_regroupement_id;
			      } );
			  }

			  return filtered_data;
		      };

		      $scope.refresh_data = function() {
			  $scope.filtered_data = filter_data( $scope.raw_data );
		      };

		      var retrieve_data = function( from_date, to_date ) {
			  EmploisDuTemps.query( { debut: from_date,
						  fin: to_date,
						  uai: $scope.current_user.profil_actif.uai } )
			      .$promise
			      .then( function success( response ) {
				  $scope.raw_data = response;
				  _($scope.raw_data).each( function( creneau ) {
				      creneau.matiere = Annuaire.get_matiere( creneau.matiere_id );
				      creneau.regroupement = Annuaire.get_regroupement( creneau.regroupement_id );
				  });
				  $scope.refresh_data();
			      });
		      };

		      var list_matieres = function(raw_data) {
			  return _.chain(raw_data)
			      .pluck('matiere_id')
			      .uniq()
			      .compact()
			      .reject( function( id ) { return id === 'undefined'; } )
			      .map(function(matiere_id) {
				  return [matiere_id, Annuaire.get_matiere(matiere_id)];
			      })
			      .object()
			      .value();
		      };

		      User.get_user().then( function( response ) {
			  $scope.current_user = response.data;

			  matieres = list_matieres( $scope.raw_data );
			  matieres_enseignees = $scope.current_user.profil_actif.matieres;
			  $scope.classes = $scope.current_user.profil_actif.classes;

			  var lundi = moment().startOf( 'week' ).toDate();
			  var dimanche = moment().endOf( 'week' ).toDate();

			  retrieve_data( lundi, dimanche );
		      } );
		  } ] );
