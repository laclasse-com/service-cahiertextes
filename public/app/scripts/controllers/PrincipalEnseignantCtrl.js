'use strict';

angular.module('cahierDeTexteApp')
    .controller('PrincipalEnseignantCtrl',
		[ '$scope', '$rootScope', '$stateParams', 'EnseignantAPI', 'CoursAPI',
		  function ( $scope, $rootScope, $stateParams, EnseignantAPI, CoursAPI ) {
		      $scope.enseignant_id = $stateParams.enseignant_id;
		      $scope.classe = -1;

		      $scope.process_data = function(  ) {
			  $scope.saisies = [];
			  if ( typeof $scope.raw_data !== 'undefined' ) {
			      _($scope.raw_data.saisies).each( function( mois ) {
				  _(mois).each( function ( saisie ) {
				      if ( ( $scope.classe == -1 ) || ( saisie.classe_id == $scope.classe ) ) {
					  $scope.saisies.push( { classe: saisie.classe_id,
								 matiere: saisie.matiere_id,
								 cours: saisie.cours,
								 devoir: saisie.devoir,
								 valide: saisie.valide,
								 cours_id: saisie.cours_id,
								 devoir_id: saisie.devoir_id } );
				      }
				  } );
			      } );

			      $scope.classes = [];
			      $scope.graphiques = {
				  pieChart: { options: $rootScope.globalPieChartOptions,
					      data: [ { color : "#00ff00",
							value: 0 },
						      { color : "#aaffaa",
							value: 0 } ] },
				  barChart: { options: $rootScope.globalLineChartOptions,
					      data: { labels: [],
						      datasets: [
							  { fillColor : "#aaffaa", pointColor : "#aaffaa",
							    strokeColor : "#88aa88", pointStrokeColor : "#88aa88",
							    data: []
							  },
							  { fillColor : "#00ff00", pointColor : "#00ff00",
							    strokeColor : "#00aa00", pointStrokeColor : "#00aa00",
							     data: []
							  } ] } }
			      };

			      _.chain($scope.saisies)
				      .groupBy('classe')
				      .map( function( classe ) {
					  return { classe: classe[0].classe,
						   filled: _(classe).size(),
						   validated: _(classe).where({valide: true}).length };
				      })
				      .each( function( classe ) {
					  $scope.classes.push( classe.classe );
					  $scope.graphiques.barChart.data.datasets[0].data.push( classe.filled );
					  $scope.graphiques.barChart.data.datasets[1].data.push( classe.validated );
				      });
			      $scope.graphiques.barChart.data.labels = $scope.classes;
			      _($scope.graphiques.pieChart.data.length).times( function( i ) {
				  $scope.graphiques.pieChart.data[i].value = $scope.graphiques.barChart.data.datasets[i].data.reduce( function( compteur, valeur ) {
				      return compteur + valeur;
				  }, 0);
			      });

			      if ( $scope.matiere == -1 ) {
				  $scope.matieres = _.chain( $scope.saisies )
				      .map( function( e ) {
					  return e.matiere;
				      } )
				      .uniq()
				      .value();
			      }

			  }
		      };

		      // Tableau
		      $scope.gridEntries = {
			  data: 'saisies',
			  enableCellEdit: false,
			  plugins: [new ngGridFlexibleHeightPlugin()],
			  rowHeight: 60,
			  columnDefs: [
			      { field: 'classe', displayName: 'Classe' }, // TODO: affichage conditionel $scope.classe
			      { field: 'matiere', displayName: 'Matière' }, // TODO: affichage conditionel $scope.matiere
			      { field: 'cours', displayName: 'Cours',
				cellTemplate: '<span style="overflow-y:auto" ng-bind-html-unsafe="row.entity.cours">{{row.entity.cours}}</span>' },
			      { field: 'devoir', displayName: 'Travail à faire',
				cellTemplate: '<span style="overflow-y:auto" ng-bind-html-unsafe="row.entity.devoir">{{row.entity.devoir}}</span>' },
			      { field: 'validated', displayName: 'Validé',
				// TODO: better
				cellTemplate: '<div class="ngSelectionCell"><input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" ng-model="row.entity.valide" ng-show="!row.entity.valide" ng-click="toggle_valide( {{row.entity.cours_id}} )" /><input tabindex="-1" class="ngSelectionCheckbox" type="checkbox" disabled checked ng-show="row.entity.valide" /></div>'}
			  ]
		      };

		      $scope.toggle_valide = function( cours_id ) {
			  CoursAPI.valide({ id: cours_id }, {});
		      };

		      $scope.validateAllEntries = function() {
			  _($scope.saisies).each( function( e ) {
			      CoursAPI.valide({ id: e.cours_id }, {});
			      e.valide = true;
			  });
		      };

		      // Récupération et consommation des données
		      EnseignantAPI.get( { enseignant_id: $scope.enseignant_id,
					   etablissement_id: '0134567A' },
					 function( response ) {
					     $scope.raw_data = response;
					     $scope.process_data();
					 } );
		  } ] );
