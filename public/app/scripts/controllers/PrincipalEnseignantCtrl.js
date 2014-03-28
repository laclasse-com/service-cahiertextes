'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantCtrl',
		[ '$scope', '$rootScope', '$stateParams', '$q', 'API', 'Cours', 'Annuaire', 'User',
		  function( $scope, $rootScope, $stateParams, $q, API, Cours, Annuaire, User ) {
		      $scope.enseignant_id = $stateParams.enseignant_id;
		      $scope.classe = null;
		      $scope.mois = $rootScope.mois;
		      $scope.moisCourant = null;
		      $scope.selectedSaisies = [];
		      $scope.matieres = {};
		      $scope.classes = {};
		      $scope.montre_valides = false;

		      $scope.filtre = function( saisies ) {
			  var data = saisies;
			  if ( $scope.moisCourant != null ) {
			      data = _(data).where({ mois: $scope.moisCourant + 1 });
			  }
			  if ( $scope.classe != null ) {
			      // .invert() suppose que les valeurs sont uniques
			      var id = _($scope.classes).invert()[$scope.classe];
			      data = _(data).where({ classe_id: id });
			  }
			  return data;
		      };

		      // Tableau
		      $scope.grid = {
			  data: 'gridSaisies',
			  selectedItems: $scope.selectedSaisies,
			  enableCellEdit: false,
			  plugins: [new ngGridFlexibleHeightPlugin()],
			  rowHeight: 64,
			  columnDefs: [
			      { field: 'classe', displayName: 'Classe',
				cellTemplate: '<span ng-bind-html-unsafe="row.entity.classe_id">{{classes[row.entity.classe_id]}}</span>' },
			      { field: 'matiere', displayName: 'Matière',
				cellTemplate: '<span ng-bind-html-unsafe="row.entity.matiere_id">{{matieres[row.entity.matiere_id]}}</span>' },
			      { field: 'cours', displayName: 'Cours',
				cellTemplate: '<span style="overflow-y:auto" ng-bind-html-unsafe="row.entity.cours.contenu">{{row.entity.cours.contenu}}</span>' },
			      { field: 'devoir', displayName: 'Travail à faire',
				cellTemplate: '<span style="overflow-y:auto" ng-bind-html-unsafe="row.entity.devoir.contenu">{{row.entity.devoir.contenu}}</span>' },
			      { field: 'validated', displayName: 'Validé',
				cellTemplate: '<div class="ngSelectionCell"><input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" ng-model="row.entity.valide" ng-show="!row.entity.valide" ng-click="grid.valide( row )" /><input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" disabled checked ng-show="row.entity.valide" /></div>'}
			  ],
			  valide: function( row ) {
			      row.entity.cours.$valide();
			      row.entity.valide = true;
			      $scope.raw_data[ row.entity.index ].valide = true;
			      $scope.graphiques.populate( $scope.gridSaisies );
			  },
			  valideSelection: function() {
			      _($scope.selectedSaisies).each( function( saisie ) {
				  saisie.cours.$valide();
				  saisie.valide = true;
				  $scope.raw_data[ saisie.index ].valide = true;
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
			      var data = $scope.filtre( saisies );
			      if ( ! $scope.montre_valides ) {
				  data = _(data).where({ valide: false });
			      }

			      $scope.gridSaisies = _(data).map( function ( saisie ) {
				  return saisie;
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

			      var data = $scope.filtre( saisies );
			      _.chain(data)
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
			      $scope.raw_data = _($scope.raw_data).map( function( saisie, index ) {
				  // on référence l'index d'origine dans chaque élément pour propager la validation
				  saisie.index = index;
				  saisie.cours = new Cours( saisie.cours );
				  // saisie.devoir = new Devoirs( saisie.devoir );
				  return saisie;
			      });

			      // consommation des données dans les graphiques et le grid
			      $scope.grid.populate( $scope.raw_data );
			      $scope.graphiques.populate( $scope.raw_data );
			  }
		      };

		      $scope.extract_matieres = function( saisies ) {
			  var matieres = {};
			  _.chain( saisies )
			      .flatten()
			      .pluck('matiere_id')
			      .uniq()
			      .each(function( matiere_id ) {
				  Annuaire.get_matiere( matiere_id ).then(
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
				  return Annuaire.get_regroupement( regroupement_id );
			      })
			      .value();
		      };

		      // Récupération et consommation des données
		      Annuaire.get_user( $scope.enseignant_id ).then(
			  function( response ) {
			      $scope.enseignant = response;
			      $scope.enseignant.matieres = _($scope.enseignant.classes).uniq( function( matiere ) {
				  return matiere.matiere_enseignee_id;
			      });
			      $scope.enseignant.prof_principal = _.chain($scope.enseignant.classes)
				  .filter( function( matiere ) {
				      return matiere.prof_principal == 'O';
				  })
				  .map( function( matiere ) {
				      return matiere.classe_libelle;
				  })
				  .value();
			  });

		      User.get_user().then( function( response ) {
			  var current_user = response.data;
			  API.get_enseignant( { enseignant_id: $stateParams.enseignant_id, uai: current_user['profil_actif']['uai'] } ).then(
				      function success( response ) {
					  $scope.raw_data = response.saisies;

					  $scope.matieres = $scope.extract_matieres( $scope.raw_data );
					  // $q.all() permet d'attendre que tout les appels d' soient résolus avant de
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
		      });
		  } ] );
