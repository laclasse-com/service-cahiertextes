'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantCtrl',
		[ '$scope', '$stateParams', '$q',
		  '$locale', 'THEME',
		  'API', 'Cours', 'Annuaire', 'User',
		  function( $scope, $stateParams, $q, $locale, THEME, API, Cours, Annuaire, User ) {
		      $scope.enseignant_id = $stateParams.enseignant_id;
		      $scope.classe = null;
		      $scope.mois = $locale.DATETIME_FORMATS.MONTH;
		      $scope.moisCourant = null;
		      $scope.gridSaisies = [];
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
				cellTemplate: '<span>{{classes[row.entity.classe_id]}}</span>' },
			      { field: 'matiere', displayName: 'Matière',
				cellTemplate: '<span>{{matieres[row.entity.matiere_id]}}</span>' },
			      { field: 'cours', displayName: 'Cours',
				cellTemplate: '<span class="scrollbar" data-ng-bind-html="row.entity.cours.contenu"></span>' },
			      { field: 'devoir', displayName: 'Travail à faire',
				cellTemplate: '<span class="scrollbar" data-ng-bind-html="row.entity.devoir.contenu"></span>' },
			      { field: 'validated', displayName: 'Validé',
				cellTemplate: '<div class="ngSelectionCell"><input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" data-ng-model="row.entity.valide" data-ng-show="!row.entity.valide" data-ng-click="grid.valide( row )" /><input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" disabled checked data-ng-show="row.entity.valide" /></div>'}
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
			      $scope.gridSaisies = $scope.filtre( saisies );
			      if ( ! $scope.montre_valides ) {
				  $scope.gridSaisies = _($scope.gridSaisies).where({ valide: false });
			      }
			  }
		      };

		      // Graphiques
		      $scope.xFunction = function(){ return function(d) { return d.label; }; };
		      $scope.yFunction = function(){ return function(d) { return d.value; }; };
		      $scope.descriptionFunction = $scope.xFunction;
		      $scope.colorFunction = function() {
			  var couleurs = [ THEME.validated.base, THEME.filled.base ];
			  return function( d, i ) {
			      return couleurs[ i ];
			  };
		      };
		      $scope.barChartxAxisTickFormatFunction = function() { return function( d ) { return d; }; };

		      $scope.graphiques = {
			  pieChart: { data: [ { label: 'valide',
						value: 0 },
					      { label: 'saisie',
						value: 0 } ] },
			  barChart: { data: [] },
			  populate: function( data ) {
			      $scope.graphiques.barChart.data = [];
			      $scope.graphiques.pieChart.data[ 0 ].value = 0;
			      $scope.graphiques.pieChart.data[ 1 ].value = 0;

			      var saisies = { key: "saisie", values: [] };
			      var valides = { key: "valide", values: [] };

			      _.chain( $scope.filtre( data ) )
				  .groupBy('classe_id')
				  .each( function( classe ) {
				      var filled = classe.length;
				      var validated = _(classe).where({valide: true}).length;

				      saisies.values.push( [ $scope.classes[ classe[0].classe_id ], filled ] );
				      valides.values.push( [ $scope.classes[ classe[0].classe_id ], validated ] );

				      $scope.graphiques.barChart.data = [ valides, saisies ];

				      $scope.graphiques.pieChart.data[0].value += validated;
				      $scope.graphiques.pieChart.data[1].value += filled - validated;
				  });
			  }
		      };

		      $scope.process_data = function(  ) {
			  if ( $scope.raw_data !== undefined ) {
			      $scope.raw_data = _($scope.raw_data)
				  .map( function( saisie, index ) {
				      // on référence l'index d'origine dans chaque élément pour propager la validation
				      saisie.index = index;
				      saisie.cours = new Cours( saisie.cours );
				      // saisie.devoir = new Devoirs( saisie.devoir );
				      return saisie;
				  } );

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
				  Annuaire.get_matiere( matiere_id ).$promise.then(
				      function( response ) {
					  matieres[ matiere_id ] = response.libelle_long;
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
		      Annuaire.get_user( $scope.enseignant_id )
			  .$promise.then(
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
			  API.get_enseignant( { enseignant_id: $stateParams.enseignant_id,
						uai: current_user['profil_actif']['uai'] } )
			      .$promise.then(
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
