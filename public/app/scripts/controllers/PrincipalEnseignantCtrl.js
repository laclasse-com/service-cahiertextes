'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantCtrl',
		[ '$scope', '$rootScope', '$stateParams', 'APIEnseignant', 'APICours', 'APIUsers', 'APIMatieres', 'APIRegroupements',
		  function( $scope, $rootScope, $stateParams, APIEnseignant, APICours, APIUsers, APIMatieres, APIRegroupements ) {
		      $scope.enseignant_id = $stateParams.enseignant_id;
		      $scope.classe = -1;
		      $scope.mois = $rootScope.mois;
		      $scope.moisCourant = -1;
		      $scope.selectedSaisies = [];
		      $scope.matieres = {};
		      $scope.classes = {};


		      // Tableau
		      $scope.grid = {
			  data: 'gridSaisies',
			  selectedItems: $scope.selectedSaisies,
			  enableCellEdit: false,
			  plugins: [new ngGridFlexibleHeightPlugin()],
			  rowHeight: 60,
			  columnDefs: [
			      { field: 'classe', displayName: 'Classe',
				cellTemplate: '<span ng-bind-html-unsafe="row.entity.classe_id">{{classes[row.entity.classe_id]}}</span>' },
			      { field: 'matiere', displayName: 'Matière',
				cellTemplate: '<span ng-bind-html-unsafe="row.entity.matiere_id">{{matieres[row.entity.matiere_id]}}</span>' },
			      { field: 'cours', displayName: 'Cours',
				cellTemplate: '<span style="overflow-y:auto" ng-bind-html-unsafe="row.entity.cours">{{row.entity.cours}}</span>' },
			      { field: 'devoir', displayName: 'Travail à faire',
				cellTemplate: '<span style="overflow-y:auto" ng-bind-html-unsafe="row.entity.devoir">{{row.entity.devoir}}</span>' },
			      { field: 'validated', displayName: 'Validé',
				cellTemplate: '<div class="ngSelectionCell"><input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" ng-model="row.entity.valide" ng-show="!row.entity.valide" ng-click="grid.valide( {{row.entity.cours_id}} )" /><input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" disabled checked ng-show="row.entity.valide" /></div>'}
			  ],
			  valide: function( cours_id ) {
			      APICours.valide({ id: cours_id }, {});
			      $scope.graphiques.populate( $scope.gridSaisies );
			  },
			  valideSelection: function() {
			      _($scope.selectedSaisies).each( function( saisie ) {
				  APICours.valide({ id: saisie.cours_id }, {});
				  saisie.valide = true;
			      });
			      $scope.graphiques.populate( $scope.gridSaisies );
			  },
			  selectionneNonValides: function() {
			      _($scope.gridSaisies).each( function( saisie, index ){
				  if( saisie.valide === false ) {
				      $scope.grid.selectItem( index, true );
				  }
			      });
			  },
			  populate: function( saisies ) {
			      $scope.gridSaisies = [];
			      _(saisies).each( function ( saisie ) {
				  $scope.gridSaisies.push( { classe_id: saisie.classe_id,
							     matiere_id: saisie.matiere_id,
							     cours: saisie.cours == -1 ? '' : saisie.cours,
							     devoir: saisie.devoir == -1 ? '' : saisie.devoir,
							     valide: saisie.valide,
							     cours_id: saisie.cours_id,
							     devoir_id: saisie.devoir_id } );
			      } );
			  }
		      };

		      // Graphiques
		      $scope.graphiques = {
			  pieChart: { options: $rootScope.globalPieChartOptions,
				      data: [ { color : $rootScope.theme.filled.base,
						value: 0 },
					      { color : $rootScope.theme.validated.base,
						value: 0 } ] },
			  barChart: { options: $rootScope.globalLineChartOptions,
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
						  } ] } },
			  populate: function( saisies ) {
			      $scope.graphiques.barChart.data.labels = [];
			      $scope.graphiques.barChart.data.datasets[0].data = [];
			      $scope.graphiques.barChart.data.datasets[1].data = [];
			      $scope.graphiques.pieChart.data[0].value = 0;
			      $scope.graphiques.pieChart.data[1].value = 0;

			      _.chain(saisies)
				  .groupBy('classe_id')
				  .map( function( classe ) {
				      return { classe_id: classe[0].classe_id,
					       filled: classe.length,
					       validated: _(classe).where({valide: true}).length };
				  })
				  .each( function( classe ) {
				      $scope.graphiques.barChart.data.labels.push( $scope.classes[classe.classe_id] );
				      $scope.graphiques.barChart.data.datasets[0].data.push( classe.filled );
				      $scope.graphiques.barChart.data.datasets[1].data.push( classe.validated );

				      $scope.graphiques.pieChart.data[0].value += classe.filled - classe.validated;
				      $scope.graphiques.pieChart.data[1].value = classe.validated;
				  });
			  }
		      };

		      $scope.process_data = function(  ) {
			  if ( $scope.raw_data !== undefined ) {
			      $scope.displayed_data = $scope.raw_data.saisies;

			      // Filtrage par mois
			      if ( $scope.moisCourant != -1 ) {
				  $scope.displayed_data = _($scope.displayed_data[ $scope.moisCourant - 1 ]);
			      }
			      $scope.displayed_data = _($scope.displayed_data).flatten();

			      // Filtrage par classe
			      if ( $scope.classe != -1 ) {
				  var id = _($scope.classes).invert()[$scope.classe];
				  $scope.displayed_data = _($scope.displayed_data).reject( function( saisie ) {
				      return ( saisie.classe_id != id );
				  });
			      }

			      $scope.grid.populate( $scope.displayed_data );
			      // TODO: compiler à partir de $scope.displayed_data
			      $scope.graphiques.populate( $scope.displayed_data );
			  }
		      };

		      // Récupération et consommation des données
		      APIUsers.get({ user_id: $scope.enseignant_id },
				   function( response ) {
				       $scope.enseignant = response;
				   },
				   function error() {
				       console.log( 'Erreur d\'apppel de l\'API Users' );
				   });

		      APIEnseignant.get({ enseignant_id: $stateParams.enseignant_id,
					  etablissement_id: '0134567A' },
					function success( response ) {
					    $scope.raw_data = response;

					    // extraction des matières
					    _.chain($scope.raw_data.saisies)
						.flatten()
						.pluck('matiere_id')
						.uniq()
						.each(function( matiere_id ) {
						    APIMatieres.get({matiere_id: matiere_id},
								    function( response ) {
									$scope.matieres[matiere_id] = response.libelle_long;
								    });
						});

					    // extraction des classes
					    _.chain($scope.raw_data.saisies)
						.flatten()
						.pluck('classe_id')
						.uniq()
						.each(function( regroupement_id ) {
						    APIRegroupements.get({regroupement_id: regroupement_id},
									 function( response ) {
									     $scope.classes[regroupement_id] = response.libelle_aaf;
									 });
						});

					    $scope.process_data();
					},
					function error() {
					    console.log( 'Erreur d\'apppel de l\'API Enseignant' );
					});
		  } ] );
