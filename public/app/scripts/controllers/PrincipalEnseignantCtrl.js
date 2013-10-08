'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantCtrl',
		[ '$scope', '$rootScope', '$stateParams', 'APIEnseignant', 'APICours', 'APIAnnuaire', 'Etablissement',
		  function( $scope, $rootScope, $stateParams, APIEnseignant, APICours, APIAnnuaire, Etablissement ) {
		      $scope.enseignant_id = $stateParams.enseignant_id;
		      $scope.classe = -1;
		      $scope.mois = $rootScope.mois;
		      $scope.moisCourant = -1;
		      $scope.raw_data = [];
		      $scope.data = [];
		      $scope.selectedSaisies = [];

		      APIAnnuaire.getUser( $scope.enseignant_id )
			  .then( function( response ) {
			      $scope.enseignant = response.data;
			      $scope.enseignant.matieres = _.chain($scope.enseignant.classes)
				  .pluck( 'matiere_libelle' )
				  .uniq()
				  .value();
			  });

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
				cellTemplate: '<div class="ngSelectionCell"><input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" ng-model="row.entity.valide" ng-show="!row.entity.valide" ng-click="valide( {{row.entity.cours_id}} )" /><input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" disabled checked ng-show="row.entity.valide" /></div>'}
			  ]
		      };
		      $scope.valide = function( cours_id ) {
			  APICours.valide({ id: cours_id }, {});
			  $scope.populate_graphs( $scope.gridSaisies );
		      };
		      $scope.valideSelection = function() {
			  _($scope.selectedSaisies).each( function( saisie ) {
			      APICours.valide({ id: saisie.cours_id }, {});
			      saisie.valide = true;
			  });
			  $scope.populate_graphs( $scope.gridSaisies );
		      };
		      $scope.selectionneNonValides = function() {
			  _($scope.gridSaisies).each( function( saisie, index ){
			      if( saisie.valide === false ) {
				  $scope.grid.selectItem( index, true );
			      }
			  });
		      };

		      $scope.populate_graphs = function( saisies ) {
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
						      } ] } }
			  };

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
		      };

		      $scope.process_data = function(  ) {
			  $scope.gridSaisies = [];

			  // Extraction des classes
			  if ( $scope.classe == -1 ) {
			      $scope.classes = _.chain( $scope.raw_data.saisies )
				  .flatten()
				  .groupBy('classe_id')
				  .keys()
				  .value();
			  }

			  // Filtrage des données
			  var saisies = [];
			  if ( $scope.moisCourant != -1 ) {
			      saisies = _($scope.raw_data.saisies[ $scope.moisCourant - 1 ]).flatten();
			  } else {
			      saisies = _($scope.raw_data.saisies).flatten();
			  }

			  // population de gridSaisies
			  _(saisies).each( function ( saisie ) {
			      if ( ( $scope.classe == -1 ) || ( saisie.classe_id == $scope.classe ) ) {
				  $scope.gridSaisies.push( { classe: saisie.classe_id,
							     matiere: saisie.matiere_id,
							     cours: saisie.cours,
							     devoir: saisie.devoir,
							     valide: saisie.valide,
							     cours_id: saisie.cours_id,
							     devoir_id: saisie.devoir_id } );
			      }
			  } );

			  $scope.populate_graphs( $scope.gridSaisies );

			  // FIXME: nggrid ne prends pas ceci en compte, affecté trop tard...
			  // $scope.grid.columnDefs[0].visible = $scope.classe == -1;
		      };

		      // Récupération et consommation des données
		      APIEnseignant.get( { enseignant_id: $scope.enseignant_id,
					   etablissement_id: '0134567A' },
					 function( response ) {
					     $scope.raw_data = response;
					     $scope.process_data();
					 } );
		  } ] );
