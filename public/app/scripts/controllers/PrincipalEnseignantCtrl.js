'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantCtrl',
		[ '$scope', '$rootScope', '$stateParams', '$q', 'APIEnseignant', 'APICours', 'APIUsers', 'APIMatieres', 'APIRegroupements',
		  function( $scope, $rootScope, $stateParams, $q, APIEnseignant, APICours, APIUsers, APIMatieres, APIRegroupements ) {
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
				  .each( function( classe ) {
				      var filled = classe.length;
				      var validated = _(classe).where({valide: true}).length;

				      $scope.graphiques.barChart.data.labels.push( $scope.classes[ classe[0].classe_id ] );
				      $scope.graphiques.barChart.data.datasets[0].data.push( filled );
				      $scope.graphiques.barChart.data.datasets[1].data.push( validated );

				      $scope.graphiques.pieChart.data[0].value += filled - validated;
				      $scope.graphiques.pieChart.data[1].value += validated;
				  });
			  }
		      };

		      $scope.process_data = function(  ) {
			  if ( $scope.raw_data !== undefined ) {
			      $scope.displayed_data = $scope.raw_data;

			      // Filtrage par mois
			      if ( $scope.moisCourant != -1 ) {
				  $scope.displayed_data = _($scope.displayed_data[ $scope.moisCourant - 1 ]);
			      }
			      $scope.displayed_data = _($scope.displayed_data).flatten();

			      // Filtrage par classe
			      if ( $scope.classe != -1 ) {
				  // .invert() suppose que les valeurs sont uniques
				  var id = _($scope.classes).invert()[$scope.classe];
				  $scope.displayed_data = _($scope.displayed_data).filter( function( saisie ) {
				      return ( saisie.classe_id == id );
				  });
			      }

			      // consommation des données dans les graphiques et le grid
			      $scope.grid.populate( $scope.displayed_data );
			      $scope.graphiques.populate( $scope.displayed_data );
			  }
		      };

		      $scope.extract_matieres = function( saisies ) {
			  var matieres = {};
			  _.chain( saisies )
			      .flatten()
			      .pluck('matiere_id')
			      .uniq()
			      .each(function( matiere_id ) {
				  APIMatieres.get({matiere_id: matiere_id},
						       function( response ) {
							   matieres[matiere_id] = response.libelle_long;
						       });
			      });
			  return matieres;
		      };

		      $scope.extract_classes_promises = function( saisies ) {
			  return _.chain( saisies )
			      .flatten()
			      .pluck('classe_id')
			      .uniq()
			      .map(function( regroupement_id ) {
				  return APIRegroupements.get({regroupement_id: regroupement_id}).$promise;
			      })
			      .value();
		      };

		      // Récupération et consommation des données
		      APIUsers.get({ user_id: $scope.enseignant_id },
				   function( response ) {
				       $scope.enseignant = response;
				   });

		      APIEnseignant.get({ enseignant_id: $stateParams.enseignant_id,
					  etablissement_id: '0134567A' },
					function success( response ) {
					    $scope.raw_data = response.saisies;

					    $scope.matieres = $scope.extract_matieres( $scope.raw_data );
					    // $q.all() permet d'attendre que tout les appels d'API soient résolus avant de
					    //   - remplir $scope.classes
					    //   - puis d'appeler $scope.process_data() qui va pouvoir consommer $scope.classes
					    //     pour passer les noms des classes aux graphiques qui ne peuvent pas profiter
					    //     du data-binding d'angularJS car ils dessinent des canvas.
					    $q.all( $scope.extract_classes_promises( $scope.raw_data ) )
						.then( function( classes ) {
						    _(classes).each(function( classe ) {
							$scope.classes[classe.id] = classe.libelle !== null ? classe.libelle : classe.libelle_aaf;
						    });
						    $scope.process_data();
						});
					});
		  } ] );
