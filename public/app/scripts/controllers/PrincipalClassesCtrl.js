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
				  var stats = par_matiere[0].par_mois.reduce( function(total, monthly_stat) {
					  return { filled: total.filled + monthly_stat.filled,
						   validated: total.validated + monthly_stat.validated } ;
				  }, { filled: 0, validated: 0 } );
				  return {
				      "regroupement_id": regroupement.regroupement_id,
				      "par_matiere": par_matiere,
				      "filled":  stats.filled,
				      "validated": stats.validated
				  };
			      });			      
			  }
			  
			  $scope.classes = $scope.raw_data.map( function( r ) {
			      return r.regroupement_id;
			  });

			  $scope.matieres = _.uniq( _.flatten( $scope.raw_data.map( function( r ) {
			      return r.par_matiere.map( function( m ) {
				  return m.matiere_id;
			      });
			  }) ) );
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
