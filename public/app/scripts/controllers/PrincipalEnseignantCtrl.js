'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantCtrl',
		[ '$scope', '$rootScope', '$stateParams', 'APIEnseignant', 'APICours', 'APIUsers',
		  function( $scope, $rootScope, $stateParams, APIEnseignant, APICours, APIUsers ) {
		      $scope.enseignant_id = $stateParams.enseignant_id;
		      $scope.classe = -1;
		      $scope.mois = $rootScope.mois;
		      $scope.moisCourant = -1;
		      $scope.selectedSaisies = [];

		      // Tableau
		      $scope.grid = {
			  data: 'gridSaisies',
			  selectedItems: $scope.selectedSaisies,
			  enableCellEdit: false,
			  plugins: [new ngGridFlexibleHeightPlugin()],
			  rowHeight: 60,
			  columnDefs: [
			      { field: 'classe', displayName: 'Classe' },
			      { field: 'matiere', displayName: 'Matière' },
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
				  var classe = _($scope.classes).findWhere({id: saisie.classe_id});
				  var matiere = _($scope.enseignant.matieres).findWhere({ id: saisie.matiere_id });
				  $scope.gridSaisies.push( { classe: classe === undefined ? 'UNK' : classe.libelle,
							     matiere: matiere === undefined ? 'UNK' : matiere.libelle,
							     cours: saisie.cours,
							     devoir: saisie.devoir,
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
				  .groupBy('classe')
				  .map( function( classe ) {
				      return { classe: classe[0].classe,
					       filled: classe.length,
					       validated: _(classe).where({valide: true}).length };
				  })
				  .each( function( classe ) {
				      $scope.graphiques.barChart.data.labels.push( classe.classe );
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
				  $scope.displayed_data = _($scope.displayed_data).reject( function( saisie ) {
				      return ( saisie.classe_id != $scope.classe );
				  });
			      }

			      $scope.grid.populate( $scope.displayed_data );
			      $scope.graphiques.populate( $scope.gridSaisies );
			  }
		      };

		      // Récupération et consommation des données
		      APIUsers.get({ user_id: $scope.enseignant_id },
				   function( response ) {
				       $scope.enseignant = response;
				       $scope.enseignant.matieres = _.chain($scope.enseignant.classes)
					   .map( function( classe ) {
					       return { id: classe.matiere_enseignee_id,
							libelle: classe.matiere_libelle };
					   })
					   .uniq( function( matiere ) {
					       return matiere.id;
					   })
					   .value();
				       $scope.classes = _.chain($scope.enseignant.classes)
					   .map( function( classe ) {
					       return { id: classe.classe_id,
							libelle: classe.classe_libelle };
					   })
					   .value();
				   },
				   function error() {
				       console.log( 'Erreur d\'apppel de l\'API Users' );
				   });

		      APIEnseignant.get({ enseignant_id: $stateParams.enseignant_id, //$scope.enseignant_id,
					  etablissement_id: '0134567A' },
					function success( response ) {
					    $scope.raw_data = response;
					    $scope.process_data();
					},
					function error() {
					    console.log( 'Erreur d\'apppel de l\'API Enseignant' );
					});
		  } ] );
