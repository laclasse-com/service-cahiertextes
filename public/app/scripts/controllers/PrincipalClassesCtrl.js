'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalClassesCtrl',
		[ '$scope', 'EmploiDuTemps', 'ClasseAPI',
		  function ($scope, EmploiDuTemps, ClasseAPI) {
		      $scope.uai = '0134567A';

		      $scope.raw_data = [];

		      $scope.classes = [];
		      $scope.matieres = [];
		      $scope.mois = [];
		      $scope.classeCourante = '';
		      $scope.moisCourant = -1;
		      $scope.matiereCourante = -1;

		      $scope.process_data = function(  ) {
			  // Extraction des classes
			  $scope.classes = $scope.raw_data.map( function( r ) {
			      return r.regroupement_id;
			  });

			  // Extraction des matières
			  $scope.matieres = _.uniq( _.flatten( $scope.raw_data.map( function( r ) {
			      return r.par_matiere.map( function( m ) {
				  return m.matiere_id;
			      });
			  }) ) );

			  // Filtrage des données
			  $scope.data = $scope.raw_data;

			  if ( $scope.classeCourante !== '' ) {
			      $scope.data = _.filter( $scope.data,
						      function( r ) {
							  return r.regroupement_id == $scope.classeCourante;
						      });
			  }

			  if ( $scope.matiereCourante != -1 ) {
			      $scope.data = $scope.data.map( function( regroupement ) {
				  var par_matiere = _.filter( regroupement.par_matiere,
							      function( r ) {
								  return r.matiere_id == $scope.matiereCourante;
							      });

				  return {
				      "regroupement_id": regroupement.regroupement_id,
				      "par_matiere": par_matiere
				  };
			      });
			  }

			  if ( $scope.moisCourant != -1 ) {
			      $scope.data = $scope.data.map(
				  function( regroupement ) {
				      return {
					  "regroupement_id": regroupement.regroupement_id,
					  "par_matiere": regroupement.par_matiere.map(
					      function( matiere ) {
						  var un_mois = _.filter( matiere.par_mois,
									  function( mois ) {
									      return mois.mois == $scope.moisCourant;
									  });
						  return { matiere_id: matiere.matiere_id,
							   par_mois: un_mois };
					      })
				      };
				  });
			  }

			  // Calcul des statistiques globales
			  $scope.global_stats = $scope.data.reduce( function( totaux, regroupement ) {
			      var stats_regroupement = regroupement.par_matiere.reduce( function( totaux, matiere ) {
				  var stats_matiere = matiere.par_mois.reduce( function( stats, mois ) {
				      return { filled: stats.filled + mois.filled,
					       validated: stats.validated + mois.validated };
				  }, { filled: 0, validated: 0 });
				  
				  return { filled: totaux.filled + stats_matiere.filled,
					   validated: totaux.validated + stats_matiere.validated };
			      }, { filled: 0, validated: 0 });
			      
			      return { filled: totaux.filled + stats_regroupement.filled,
				       validated: totaux.validated + stats_regroupement.validated };
			  }, { filled: 0, validated: 0 });
		      };

		      EmploiDuTemps.getMois().success( function( response ) {
			  $scope.mois = response.mois;
		      });

		      ClasseAPI.query( { uai: $scope.uai, id: '' },
				       function( response ) {
					   $scope.raw_data = response;
					   $scope.process_data();
				       });
		  } ] );
