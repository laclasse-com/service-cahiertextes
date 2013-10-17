'use strict';

angular.module('cahierDeTexteApp')
    .controller('EnseignantCtrl',
		[ '$scope', '$rootScope', '$modal', '$q', 'EmploisDuTemps', 'Matieres', 'Cours', 'Devoirs', 'TypesDeDevoir', 'Regroupements',
		  function ( $scope, $rootScope, $modal, $q, EmploisDuTemps, Matieres, Cours, Devoirs, TypesDeDevoir, Regroupements ) {
		      $scope.matieres = {};
		      $scope.classes = {};
		      $scope.classe = -1;

		      // configuration du composant calendrier
		      $scope.calendar = { options: $rootScope.globalCalendarOptions,
					  events: [  ] };
		      $scope.calendar.options.defaultView = 'agendaWeek';
		      $scope.calendar.options.height = 600;
		      $scope.calendar.options.editable = false;
		      $scope.calendar.options.header = { left: 'title',
							 center: 'agendaDay agendaWeek month',
							 right: 'today prev,next' };

		      $scope.calendar.options.eventRender = function( event, element ) {
			  element.find('.fc-event-title').append( event.description );
		      };

		      // ouverture de la popup de création/édition
		      $scope.calendar.options.eventClick = function( event ) {
			  var create_cours = function( creneau ) {
			      var cours = new Cours({
				  cahier_de_textes_id: creneau.details.cahier_de_textes_id,
				  creneau_emploi_du_temps_id: creneau.details.creneau_emploi_du_temps_id,
				  date_cours: creneau.start
			      });
			      cours.create = true;

			      return cours;
			  };
			  var create_devoir = function( cours, types_de_devoir ) {
			      var date = new Date();
			      var devoir = new Devoirs({ cours_id: cours.id,
							 date_due: date.getFullYear() + '-' + date.getMonth() + '-' + date.getDay(),
							 type_devoir_id: types_de_devoir[1].id });
			      devoir.create = true;

			      return devoir;
			  };

			  $scope.creneau = _(event.source.events).findWhere({_id: event._id});
			  $scope.matiere = event.title;

			  // 1. cours
			  if ( $scope.creneau.details.cours.id !== undefined ) {
			      $scope.cours = Cours.get( { id: $scope.creneau.details.cours.id } ).$promise;
			      $scope.cours.then( function success() {
				  $scope.cours.create = false;
			      },
						 function error() {
						     $scope.cours = create_cours( $scope.creneau );
						 });
			  } else {
			      $scope.cours = create_cours( $scope.creneau );
			  }

			  // 2. devoir
			  if ( $scope.creneau.details.devoir.id !== undefined ) {
			      $scope.devoir = Devoirs.get( { id: $scope.creneau.details.devoir.id } ).$promise;
			      $scope.devoir.then( function success() {
				  $scope.devoir.create = false;
			      },
						  function error() {
						      $q.all( $scope.types_de_devoir, $scope.cours )
							  .then( function() {
							      $scope.devoir = create_devoir( $scope.cours, $scope.types_de_devoir );
							  });
						  });
			  } else {
			      $q.all( $scope.types_de_devoir, $scope.cours )
				  .then( function() {
				      $scope.devoir = create_devoir( $scope.cours, $scope.types_de_devoir );
				  });
			  }

			  // 3. ouverture de la popup
			  $q.all( $scope.types_de_devoir, $scope.cours, $scope.devoir )
			      .then( function() {
				  $scope.ouvre_popup(  );
			      });
		      };

		      // popup de création/édition
		      var modalInstanceCtrl = function( $scope, $rootScope, $modalInstance, matiere, cours, devoir, types_de_devoir ) {
			  // Attention, $scope ici est le scope de la popup, plus celui d'EnseignantCtrl !
			  $scope.matiere = matiere;
			  $scope.cours = cours;
			  $scope.devoir = devoir;
			  $scope.types_de_devoir = types_de_devoir;
			  $scope.tinyMCEOptions = $rootScope.tinyMCEOptions;

			  $scope.fermer = function() {
			      $modalInstance.close( { cours: $scope.cours,
						      devoir: $scope.devoir} );
			  };

			  $scope.valider = function() {
			      var promesse = $q.when(true);

			      if ( $scope.cours.contenu.length > 0 ) {
				  $scope.cours.dirty = true;
				  if ( $scope.cours.create ) {
				      promesse = $scope.cours.$save();
				  } else {
				      promesse = $scope.cours.$update();
				  }
			      }

			      promesse.then( function( cours ) {
				  $scope.cours = cours;
				  if ( $scope.devoir.contenu.length > 0 ) {
				      $scope.devoir.dirty = true;
				      if ( $scope.devoir.create ) {
					  $scope.devoir.cours_id = $scope.cours.id;
					  $scope.devoir.$save();
				      } else {
					  $scope.devoir.$update();
				      }
				  }
			      });

			      $scope.fermer();
			  };
		      };

		      $scope.ouvre_popup = function(  ) {
			  $modal.open({ templateUrl: 'views/modals/enseignant/detail_emploi_du_temps.html',
					controller: modalInstanceCtrl,
					resolve: { matiere: function() { return $scope.matiere; },
						   cours: function() { return $scope.cours; },
						   devoir: function() { return $scope.devoir; },
						   types_de_devoir: function() { return $scope.types_de_devoir; } } })
			      .result.then( function ( objets ) { //évécuté à la fermeture de la popup
				  if ( ( objets.cours.dirty ) || ( objets.devoir.dirty ) ) {
				      var index = _($scope.calendar.events[0]).indexOf($scope.creneau);
				      var updated_event = $scope.update_fullCalendar_event( $scope.creneau, objets.cours, objets.devoir );

				      _.chain(updated_event)
					  .keys()
					  .reject(function( key ) { //updated_event n'a pas de title
					      return key == "title";
					  })
					  .each( function( propriete ) {
					      $scope.calendar.events[0][ index ][ propriete ] = updated_event[ propriete ];
					  });
				      $scope.emploi_du_temps.fullCalendar( 'renderEvent', $scope.calendar.events[0][ index ] );
				  }
			      });
		      };

		      // helper
		      $scope.update_fullCalendar_event = function( event, cours, devoir ) {
			  var calendar_event = { details: { matiere_id: event.details.matiere_id,
							    cahier_de_textes_id: event.details.cahier_de_textes_id,
							    creneau_emploi_du_temps_id: event.details.creneau_emploi_du_temps_id,
							    cours: cours,
							    devoir: devoir },
						 allDay: false,
						 title: '',
						 description: '',
						 start: event.start,
						 end: event.end,
						 color: '' };

			  // choix de la couleur
			  if ( ( cours.contenu !== undefined ) && ( cours.contenu.length > 0 ) ) {
			      if ( ( devoir.contenu !== undefined ) && ( devoir.contenu.length > 0 ) ) {
				  calendar_event.color = $rootScope.theme.calendar.devoir;
			      } else {
				  calendar_event.color = $rootScope.theme.calendar.saisie;
			      }
			  } else {
			      calendar_event.color = $rootScope.theme.calendar.vide;
			  }

			  var clever_truncate = function( text, length ) {
			      if ( text.length > length ) {
				  var result = text.substring( 0, length );
				  result = result.substring( 0, result.lastIndexOf(' ') );
				  result += '…';
				  return result;
			      } else {
				  return text;
			      }
			  };

			  // composition de la description
			  if ( _(cours).size() > 0 ) {
			      calendar_event.description += '<br><span style="color:' + $rootScope.calendar.couleurs.cours + '">';
			      calendar_event.description += clever_truncate( cours.contenu, $rootScope.calendar.cours_max_length );
			      calendar_event.description += '</span>';
			      if ( _(devoir).size() > 0 ) {
				  calendar_event.description += '<br><span style="color:' + $rootScope.calendar.couleurs.devoir + '">';
				  calendar_event.description += clever_truncate( devoir.contenu, $rootScope.calendar.devoir_max_length );
				  calendar_event.description += '</span>';
			      }
			  }

			  // composition du titre
			  if ( $scope.matieres[ event.details.matiere_id ] === undefined ) {
			      $scope.matieres[ event.details.matiere_id ] = Matieres.get({ matiere_id: event.details.matiere_id }).$promise;
			  }
			  $scope.matieres[ event.details.matiere_id ].then( function success( response ) {
			      calendar_event.title = response.libelle_long;
			  });

			  return calendar_event;
		      };

		      $scope.assemble_fullCalendar_event = function( item_emploi_du_temps ) {
			  return $scope.update_fullCalendar_event( { details: { matiere_id: item_emploi_du_temps.matiere_id,
										cahier_de_textes_id: item_emploi_du_temps.cahier_de_textes_id,
										creneau_emploi_du_temps_id: item_emploi_du_temps.creneau_emploi_du_temps_id },
								     start: new Date( item_emploi_du_temps.start ),
								     end: new Date( item_emploi_du_temps.end ) },
								   item_emploi_du_temps.cours,
								   item_emploi_du_temps.devoir );
		      };

		      $scope.extract_classes_promises = function( data ) {
			  return _.chain( data )
			      .pluck( 'regroupement_id' )
			      .uniq()
			      .map( function( regroupement_id ) {
				  return Regroupements.get({ regroupement_id: regroupement_id }).$promise;
			      })
			      .value();
		      };

		      $scope.process_data = function() {
			  var filtered_data = $scope.raw_data;

			  // Filtrage par classe
			  if ( $scope.classe != -1 ) {
			      // .invert() suppose que les valeurs sont uniques
			      var id = _($scope.classes).invert()[$scope.classe];
			      filtered_data = _($scope.raw_data).filter( function( creneau ) {
				  return creneau.regroupement_id == id;
			      });
			  }

			  $scope.calendar.events[0] = _(filtered_data).map( function( event ) {
			      return $scope.assemble_fullCalendar_event( event );
			  } );
		      };

		      $scope.types_de_devoir = TypesDeDevoir.query();

		      // population des créneaux d'emploi du temps avec les cours et devoirs éventuels
		      EmploisDuTemps.query( function( response ) {
			  $scope.raw_data = response;

			  // Extraction des classes
			  $q.all( $scope.extract_classes_promises( $scope.raw_data ) )
			      .then( function( classes ) {
				  _(classes).each(function( classe ) {
				      $scope.classes[classe.id] = classe.libelle !== null ? classe.libelle : classe.libelle_aaf;
				  });
			      });

			  $scope.process_data();
		      });
		  } ] );
