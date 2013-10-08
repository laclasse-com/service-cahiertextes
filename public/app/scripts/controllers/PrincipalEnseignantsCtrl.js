'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantsCtrl',
		[ '$scope', '$rootScope', 'APIEnseignants', 'APIUsers',
		  function( $scope, $rootScope, APIEnseignants, APIUsers ) {
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

					       $scope.radar.data.labels.push( 'UNK' );
					   });
				       }
				     };
		      $scope.grid = { data: 'enseignants',
				      enableCellEdit: true,
				      plugins: [new ngGridFlexibleHeightPlugin()],
				      columnDefs: [
					  { field: 'name', displayName: 'Nom',
					    cellTemplate: '<div><a href="#/principal/enseignant/{{row.getProperty(\'id\')}}">{{row.entity[col.field]}}</a></div>' },
					  { field: 'discipline', displayName: 'Discipline' },
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

					      var row = { id: enseignant.enseignant_id,
							  name: 'UNK',
							  discipline: [],
							  stats: stats.validated + '/' + stats.filled };

					      // FIXME: debug data
					      APIUsers.get({ user_id: 'VAA60462' },
							   // APIUsers.get({ user_id: enseignant.enseignant_id },
							   function( response ) {
							       row.name = response.full_name;
							       row.discipline = _.chain(response.classes)
								   .pluck( 'matiere_libelle' )
								   .uniq()
								   .value();
							   },
							   function error() {
							       console.log( 'Erreur d\'apppel de l\'API Users' );
							   });

					      return row;
					  });
				      }
				    };
		      $scope.annee = $rootScope.mois;
		      $scope.classe = -1;
		      $scope.mois = -1;
		      $scope.enseignant = -1;

		      $scope.process_data = function( data ) {
			  console.log('$scope.process_data called !')
			  if ( data !== undefined ) {
			      // extraction des classes
			      $scope.classes = _.chain(data)
				  .pluck('classes')
				  .flatten()
				  .pluck('regroupement')
				  .uniq()
				  .value();

			      // filtrage sur la classe sélectionnée
			      if ( $scope.classe != -1 ) {
				  data = _.chain(data)
				      .map( function( enseignant ) {
					  return { enseignant_id: enseignant.enseignant_id,
						   classes: _(enseignant.classes).reject( function( classe ) {
						       return classe.regroupement != $scope.classe;
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
				  data = _(data).map( function( enseignant ) {
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

			      $scope.radar.populate( data );
			      $scope.grid.populate( data );
			  }
		      };

		      // Récupération et consommation des données
		      APIEnseignants.query( { etablissement_id: '0134567A' },
					    function success( response ) {
						$scope.process_data( response );
					    } );
		  } ] );
