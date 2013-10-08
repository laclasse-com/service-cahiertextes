'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantCtrl',
		[ '$scope', '$rootScope', '$stateParams', 'APIEnseignant', 'APICours', 'APIMatieres', 'APIRegroupements', 'APIUsers',
		  function( $scope, $rootScope, $stateParams, APIEnseignant, APICours, APIMatieres, APIRegroupements, APIUsers ) {
		      // FIXME: dummy enseignant_id
		      $scope.enseignant_id = 'VAA60462';
		      console.log($stateParams.enseignant_id)
		      $scope.classe = -1;
		      $scope.mois = $rootScope.mois;
		      $scope.moisCourant = -1;

		      // Tableau
		      $scope.grid = {
			  data: 'gridSaisies',
			  selectedItems: 'selectedSaisies',
			  enableCellEdit: false,
			  plugins: [new ngGridFlexibleHeightPlugin()],
			  rowHeight: 60,
			  columnDefs: [
			      { field: 'classe.libelle', displayName: 'Classe' },
			      { field: 'matiere.libelle_long', displayName: 'Matière' },
			      { field: 'cours', displayName: 'Cours',
				cellTemplate: '<span style="overflow-y:auto" ng-bind-html-unsafe="row.entity.cours">{{row.entity.cours}}</span>' },
			      { field: 'devoir', displayName: 'Travail à faire',
				cellTemplate: '<span style="overflow-y:auto" ng-bind-html-unsafe="row.entity.devoir">{{row.entity.devoir}}</span>' },
			      { field: 'validated', displayName: 'Validé',
				cellTemplate: '<div class="ngSelectionCell"><input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" ng-model="row.entity.valide" ng-show="!row.entity.valide" ng-click="grid.valide( {{row.entity.cours_id}} )" /><input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" disabled checked ng-show="row.entity.valide" /></div>'}
			  ],
			  valide: function( cours_id ) {
			      APICours.valide({ id: cours_id }, {});
			      $scope.populate_graphs( $scope.gridSaisies );
			  },
			  valideSelection: function() {
			      _($scope.selectedSaisies).each( function( saisie ) {
				  APICours.valide({ id: saisie.cours_id }, {});
				  saisie.valide = true;
			      });
			      $scope.populate_graphs( $scope.gridSaisies );
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
			      $scope.selectedSaisies = [];

			      _(saisies).each( function ( saisie ) {
				  if ( ( $scope.classe == -1 ) || ( saisie.classe_id == $scope.classe ) ) {
				      var record = { classe: '',
						     matiere: '',
						     cours: saisie.cours,
						     devoir: saisie.devoir,
						     valide: saisie.valide,
						     cours_id: saisie.cours_id,
						     devoir_id: saisie.devoir_id };
				      APIMatieres.get({ matiere_id: saisie.matiere_id },
						      function success( response ) {
							  record.matiere = response.libelle_long;
						      },
						      function error(  ) {
							  record.matiere = 'Matière inconnue';
						      });
				      APIRegroupements.get({ regroupement_id: saisie.classe_id },
							   function success( response ) {
							       record.regroupement = response.libelle;
							   },
							   function error(  ) {
							       record.regroupement = 'Classe inconnue';
							   });
				      
				      $scope.gridSaisies.push( record );
				  }
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

		      $scope.process_data = function( data ) {
			  if ( data !== undefined ) {
			      // Extraction des classes
			      if ( $scope.classe == -1 ) {
				  $scope.classes = _.chain( data.saisies )
				      .flatten()
				      .groupBy('classe_id')
				      .keys()
				      .map( function( key ) {
					  var regroupement = APIRegroupements.get({ regroupement_id: key });
					  return regroupement.libelle;
				      })
				      .value();
			      }

			      // Filtrage des données
			      var saisies = [];
			      if ( $scope.moisCourant != -1 ) {
				  saisies = _(data.saisies[ $scope.moisCourant - 1 ]).flatten();
			      } else {
				  saisies = _(data.saisies).flatten();
			      }

			      $scope.grid.populate( saisies );
			      $scope.graphiques.populate( $scope.gridSaisies );

			      // FIXME: nggrid ne prends pas ceci en compte, affecté trop tard...
			      // $scope.grid.columnDefs[0].visible = $scope.classe == -1;
			  }
		      };

		      // Récupération et consommation des données
		      APIUsers.get({ user_id: $scope.enseignant_id },
				   function( response ) {
				       $scope.enseignant = response;
				       $scope.enseignant.matieres = _.chain($scope.enseignant.classes)
					   .pluck( 'matiere_libelle' )
					   .uniq()
					   .value();
				   },
				   function error() {
				       console.log( 'Erreur d\'apppel de l\'API Users' );
				   });

		      APIEnseignant.get({ enseignant_id: $stateParams.enseignant_id, //$scope.enseignant_id,
					  etablissement_id: '0134567A' },
					function success( response ) {
					    $scope.process_data( response );
					},
					function error() {
					    console.log( 'Erreur d\'apppel de l\'API Enseignant' );
					});
		  } ] );
