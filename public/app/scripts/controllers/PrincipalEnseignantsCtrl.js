'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantsCtrl',
		[ '$scope', '$rootScope', '$q', 'Enseignants', 'Users', 'Regroupements',
		  function( $scope, $rootScope, $q, Enseignants, Users, Regroupements ) {
		      $scope.annee = $rootScope.mois;
		      $scope.classe = -1;
		      $scope.mois = -1;
		      $scope.enseignant = -1;
		      $scope.classes = {};
		      $scope.details_enseignants = {};

		      $scope.radar = { options: $rootScope.globalRadarChartOptions,
				       data: { labels: [],
					       datasets: [
						   { fillColor : $rootScope.theme.filled.base,
						     pointColor : $rootScope.theme.filled.base,
						     strokeColor : $rootScope.theme.filled.stroke,
						     pointStrokeColor : $rootScope.theme.filled.stroke,
						     data: []
						   },
						   { fillColor : $rootScope.theme.validated.base,
						     pointColor : $rootScope.theme.validated.base,
						     strokeColor : $rootScope.theme.validated.stroke,
						     pointStrokeColor : $rootScope.theme.validated.stroke,
						     data: []
						   } ] },
				       populate: function( enseignants ) {
					   $scope.radar.data.datasets[0].data = [];
					   $scope.radar.data.datasets[1].data = [];

					   _(enseignants).each( function( enseignant ) {
					       var stats = _(enseignant.classes).reduce( function( totaux, classe ) {
						   var stats = _(classe.statistiques).reduce( function( totaux, mois ) {
						       return { filled: totaux.filled + mois.filled,
								validated: totaux.validated + mois.validated};
						   }, { filled: 0, validated: 0});

						   return { filled: totaux.filled + stats.filled,
							    validated: totaux.validated + stats.validated};
					       }, { filled: 0, validated: 0});

					       $scope.radar.data.datasets[0].data.push( stats.filled );
					       $scope.radar.data.datasets[1].data.push( stats.validated );

					       // $scope.radar.data.labels.push( $scope.details_enseignants[enseignant.enseignant_id].nom );
					       $scope.radar.data.labels.push( '' );
					   });
				       }
				     };
		      $scope.grid = { data: 'enseignants',
				      enableCellEdit: true,
				      plugins: [new ngGridFlexibleHeightPlugin()],
				      columnDefs: [
					  { field: 'nom', displayName: 'Nom',
					    cellTemplate: '<div><a href="#/principal/enseignant/{{row.getProperty(\'id\')}}">{{row.entity[col.field]}}</a></div>' },
					  { field: 'matieres', displayName: 'Matières enseignées',
					    cellTemplate: '<span data-ng-repeat="matiere in row.entity.matieres">{{matiere}}{{($last != true) && ", " || ""}}</span>' },
					  { field: 'stats', displayName: 'Statistiques' }],
				      populate: function( enseignants ) {
					  $scope.enseignants = _(enseignants).map( function( enseignant ) {
					      var stats = _(enseignant.classes).reduce( function( totaux, classe ) {
						  var stats = _(classe.statistiques).reduce( function( totaux, mois ) {
						      return { filled: totaux.filled + mois.filled,
							       validated: totaux.validated + mois.validated};
						  }, { filled: 0, validated: 0});

						  return { filled: totaux.filled + stats.filled,
							   validated: totaux.validated + stats.validated};
					      }, { filled: 0, validated: 0});

					      return { id: enseignant.enseignant_id,
						       nom: $scope.details_enseignants[enseignant.enseignant_id].nom,
						       matieres: $scope.details_enseignants[enseignant.enseignant_id].matieres,
						       stats: stats.validated + '/' + stats.filled };
					  });
				      }
				    };

		      $scope.extract_classes_promises = function( data ) {
			  return _.chain(data)
			      .pluck('classes')
			      .flatten()
			      .pluck('regroupement')
			      .uniq()
			      .map(function( regroupement_id ) {
				  return Regroupements.get({regroupement_id: regroupement_id}).$promise;
			      })
			      .value();
		      };

		      $scope.extract_enseignants_promises = function( data ) {
			  return _(data).pluck('enseignant_id')
			      .map(function ( enseignant_id ) {
				  return Users.get({ user_id: enseignant_id }).$promise;
			      });
		      };

		      $scope.process_data = function(  ) {
			  if ( $scope.raw_data !== undefined ) {
			      $scope.displayed_data = $scope.raw_data;

			      // filtrage sur la classe sélectionnée
			      if ( $scope.classe != -1 ) {
				  // .invert() suppose que les valeurs sont uniques
				  var id = _($scope.classes).invert()[$scope.classe];
				  $scope.displayed_data = _.chain($scope.displayed_data)
				      .map( function( enseignant ) {
					  return { enseignant_id: enseignant.enseignant_id,
						   classes: _(enseignant.classes).reject( function( classe ) {
						       return classe.regroupement != id;
						   })
						 };
				      })
				      .reject( function( enseignant ) { // TODO: chercher une meilleure solution
					  return enseignant.classes.length === 0;
				      })
				      .value();
			      }

			      // filtrage sur le mois sélectionné
			      if ( $scope.mois != -1 ) {
				  $scope.displayed_data = _($scope.displayed_data).map( function( enseignant ) {
				      return { enseignant_id: enseignant.enseignant_id,
					       classes: _(enseignant.classes).map( function( classe ) {
						   return { regroupement: classe.regroupement,
							    statistiques: _(classe.statistiques).reject( function( mois ) {
								return mois.month != $scope.mois;
							    })
							  };
					       })
					     };
				  });
			      }

			      $scope.radar.populate( $scope.displayed_data );
			      $scope.grid.populate( $scope.displayed_data );
			  }
		      };

		      // Récupération et consommation des données
		      Enseignants.query( { etablissement_id: '0134567A' },
					    function success( response ) {
						$scope.raw_data = _(response).reject( function( enseignant ) {
						    return enseignant.enseignant_id === ''; 
						});

						$q.all( $scope.extract_enseignants_promises( $scope.raw_data ) )
						    .then( function( enseignants ) {
							_(enseignants).each(function( enseignant ) {
							    $scope.details_enseignants[enseignant.id_ent] = { nom: enseignant.full_name,
													  matieres: _.chain(enseignant.matieres_enseignees)
													  .pluck( 'libelle_long' )
													  .uniq()
													  .value() };
							});

							$q.all( $scope.extract_classes_promises( $scope.raw_data ) )
							    .then( function( classes ) {
								_(classes).each(function( classe ) {
								    $scope.classes[classe.id] = classe.libelle !== null ? classe.libelle : classe.libelle_aaf;
								});
								$scope.process_data();
							    });
						    });
					    } );
		  } ] );
