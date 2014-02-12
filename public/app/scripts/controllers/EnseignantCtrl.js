'use strict';

angular.module('cahierDeTexteApp')
    .controller('EnseignantCtrl',
		[ '$scope', '$rootScope', '$modal', '$q', 'API', 'Annuaire', 'Cours', 'Devoirs', 'EmploisDuTemps', 'CurrentUser', 'CreneauEmploiDuTemps',
		  function ( $scope, $rootScope, $modal, $q, API, Annuaire, Cours, Devoirs, EmploisDuTemps, CurrentUser, CreneauEmploiDuTemps ) {
		      $scope.loading = true;

		      ///////////////////////////////////////// Sous-contrôleurs
		      // popup de création/édition des cours et devoirs ////////
		      var editionModalInstanceCtrl = function( $scope, $rootScope, $modalInstance, cours, devoirs, types_de_devoir, matiere_id, regroupement_id, raw_data, classes, matieres ) {
			  // Attention, $scope ici est le scope de la popup, plus celui d'EnseignantCtrl !
			  $scope.matieres = matieres;
			  $scope.classes = classes;
			  $scope.cours = cours;
			  $scope.devoirs = devoirs;
			  $scope.types_de_devoir = types_de_devoir;
			  $scope.matiere_id = matiere_id;
			  $scope.regroupement_id = regroupement_id;
			  $scope.tinyMCEOptions = $rootScope.tinyMCEOptions;

			  if ( $scope.matiere_id == '' ) {
			      $scope.matieres_array = _($scope.matieres).keys().map( function( key ) {
				  return { id: key, nom: $scope.matieres[key].libelle_long };
			      });
			  }
			  if ( $scope.regroupement_id == '' ) {
			      $scope.classes_array = _($scope.classes).keys().map( function( key ) {
				  return { id: key, nom: $scope.classes[key] };
			      });
			  }

			  $scope.creneaux_similaires = _.chain(raw_data)
			      .where({matiere_id: $scope.matiere_id})
			      .reject(function( creneau ) {
				  return creneau.regroupement_id == $scope.regroupement_id;
			      })
			      .value();

			  var create_devoir = function( cours, types_de_devoir ) {
			      var date = new Date();
			      var devoir = new Devoirs({ cours_id: cours.id,
							 date_due: date.getFullYear() + '-' + date.getMonth() + '-' + date.getDay(),
							 type_devoir_id: types_de_devoir[1].id });
			      devoir.create = true;

			      return devoir;
			  };

			  $scope.ajout_devoir = function() {
			      $scope.devoirs.push( create_devoir( $scope.cours, $scope.types_de_devoir ) );
			  };

			  $scope.fermer = function() {
			      $modalInstance.close( { cours: $scope.cours,
						      devoirs: $scope.devoirs} );
			  };

			  $scope.dupliquer = function() {
			      console.log('TODO: la duplication en action !')
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
				  $scope.devoirs = _($scope.devoirs).map(function( devoir ) {
				      if ( devoir.contenu.length > 0 ) {
					  devoir.dirty = true;
					  if ( devoir.create ) {
					      devoir.cours_id = $scope.cours.id;
					      devoir.$save().then( function( new_devoir ) {
						  devoir.id = new_devoir.id;
					      });
					  } else {
					      devoir.$update();
					  }
				      }
				      return devoir;
				  });
			      });

			      $scope.fermer();
			  };
		      };

		      //////////////////////// Code du contrôleur principal proprement dit
		      $scope.build_EdT_from_scratch = true;

		      $scope.matieres = {};
		      $scope.classes = {};
		      $scope.classe = -1;

		      // configuration du composant calendrier /////////////////
		      $scope.calendar = { options: $rootScope.globalCalendarOptions,
					  events: [  ] };
		      $scope.calendar.options.defaultView = 'agendaWeek';
		      $scope.calendar.options.height = 600;
		      $scope.calendar.options.header = { left: 'title',
							 center: 'agendaDay agendaWeek month',
							 right: 'today prev,next' };
		      $scope.calendar.options.eventRender = function( event, element ) {
			  element.find('.fc-event-title').append( event.description );
		      };

		      if ( $scope.build_EdT_from_scratch ) {
			  $scope.calendar.options.editable = true;
			  $scope.calendar.options.disableDragging = true;
			  $scope.calendar.options.selectable = true;
			  $scope.calendar.options.selectHelper = true;
			  $scope.calendar.options.select = function(start, end, allDay) {
			      var cedt = new CreneauEmploiDuTemps({
				  regroupement_id: '',
				  jour_de_la_semaine: start.getDay() + 1,
				  heure_debut: start,
				  heure_fin: end,
				  matiere_id: ''
			      });
			      // cedt.$save();
			      cedt.dirty = true;
			      console.log(cedt)

			      console.log( 'créer l\'événement dans fullcalendar' );

			      // TODO: refactor this with $scope.calendar.options.eventClick()
			      var create_cours = function( creneau ) {
				  var cours = new Cours({
				      cahier_de_textes_id: '',
				      creneau_emploi_du_temps_id: cedt.id,
				      date_cours: start
				  });
				  cours.create = true;

				  return cours;
			      };

			      $scope.creneau = cedt;
			      $scope.matiere_id = cedt.matiere_id;
			      $scope.regroupement_id = cedt.regroupement_id;

			      // 1. cours
			      $scope.cours = create_cours( $scope.creneau );

			      // 2. devoir
			      $scope.devoirs = [];

			      // 3. ouverture de la popup
			      $q.all( $scope.types_de_devoir, $scope.cours, $scope.devoirs )
				  .then( function() {
				      $scope.ouvre_popup_edition(  );
				  });

			      console.log('passer id')

			      $scope.emploi_du_temps.fullCalendar('unselect');
			  };
		      }
		      else {
			  $scope.calendar.options.editable = false;
		      }

		      // // ouverture de la popup de création/édition //////////
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

			  $scope.creneau = _(event.source.events).findWhere({_id: event._id});
			  $scope.matiere_id = event.details.matiere_id;
			  $scope.regroupement_id = event.details.regroupement_id;

			  // 1. cours
			  if ( $scope.creneau.details.cours.id !== undefined ) {
			      $scope.cours = API.get_cours( { id: $scope.creneau.details.cours.id } );
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
			  if ( $scope.creneau.details.devoirs.length > 0 ) {
			      // $scope.devoirs = _($scope.creneau.details.devoirs).map( function( devoir ) {
			      //	  return API.get_devoir( { id: devoir.id } ).then( function( vrai_devoir ) {
			      //	      return vrai_devoir;
			      //	  });
			      // });
			      $scope.devoirs = [];
			      _($scope.creneau.details.devoirs).each( function( devoir ) {
				  API.get_devoir( { id: $scope.creneau.details.devoirs[0].id } )
				      .then( function( vrai_devoir ) {
					  $scope.devoirs.push( vrai_devoir );
				      } );
			      } );
			      $scope.devoirs.create = false;

			  } else {
			      $scope.devoirs = [];
			  }

			  // 3. ouverture de la popup
			  $q.all( $scope.types_de_devoir, $scope.cours )
			      .then( function() {
				  if ( _($scope.devoirs).isEmpty() ) {
				      $scope.ouvre_popup_edition(  );
				  } else {
				      $q.all( $scope.devoirs ).then( function() {
					  $scope.ouvre_popup_edition(  );
				      } );
				  }
			      });
		      };

		      $scope.ouvre_popup_edition = function(  ) {
			  $modal.open({ templateUrl: 'app/views/modals/enseignant/detail_emploi_du_temps.html',
					controller: editionModalInstanceCtrl,
					resolve: { raw_data: function() { return $scope.raw_data; },
						   matieres: function() { return $scope.matieres; },
						   classes: function() { return $scope.classes; },
						   matiere_id: function() { return $scope.matiere_id; },
						   regroupement_id: function() { return $scope.regroupement_id; },
						   cours: function() { return $scope.cours; },
						   devoirs: function() { return $scope.devoirs; },
						   types_de_devoir: function() { return $scope.types_de_devoir; } } })
			      .result.then(
				  // éxécuté à la fermeture de la popup
				  function ( objets ) {
				      objets.devoirs = _(objets.devoirs).filter(function(devoir) {
					  return _(devoir).has( 'id' );
				      });
				      if ( ( objets.cours.dirty ) || ( objets.devoirs.dirty ) ) {
					  var index = _($scope.calendar.events[0]).indexOf($scope.creneau);
					  var updated_event = $scope.update_fullCalendar_event( $scope.creneau, objets.cours, objets.devoirs );

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
				  }
			      );
		      };

		      // consommation des données //////////////////////////////
		      // helper
		      $scope.update_fullCalendar_event = function( event, cours, devoirs ) {
			  var calendar_event = { details: { matiere_id: event.details.matiere_id,
							    regroupement_id: event.details.regroupement_id,
							    cahier_de_textes_id: event.details.cahier_de_textes_id,
							    creneau_emploi_du_temps_id: event.details.creneau_emploi_du_temps_id,
							    cours: cours,
							    devoirs: devoirs },
						 allDay: false,
						 title: '',
						 description: '',
						 start: event.start,
						 end: event.end,
						 color: '' };

			  // choix de la couleur
			  if ( ( cours.contenu !== undefined ) && ( cours.contenu.length > 0 ) ) {
			      if ( devoirs.length > 0 ) {
				  calendar_event.color = $rootScope.theme.calendar.devoir;
			      } else {
				  if ( cours.date_validation != null ) {
				      calendar_event.color = $rootScope.theme.validated.base;
				  } else {
				      calendar_event.color = $rootScope.theme.calendar.saisie;
				  }
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
			  }

			  // composition du titre
			  $scope.matieres[ event.details.matiere_id ] = Annuaire.get_matiere( event.details.matiere_id );

			  $scope.matieres[ event.details.matiere_id ].then( function success( response ) {
			      $scope.matieres[ event.details.matiere_id ] = response;
			      calendar_event.title = $scope.matieres[ event.details.matiere_id ].libelle_long;
			  });

			  return calendar_event;
		      };

		      $scope.assemble_fullCalendar_event = function( item_emploi_du_temps ) {
			  return $scope.update_fullCalendar_event( { details: { matiere_id: item_emploi_du_temps.matiere_id,
										regroupement_id: item_emploi_du_temps.regroupement_id,
										cahier_de_textes_id: item_emploi_du_temps.cahier_de_textes_id,
										creneau_emploi_du_temps_id: item_emploi_du_temps.creneau_emploi_du_temps_id },
								     start: new Date( item_emploi_du_temps.start ),
								     end: new Date( item_emploi_du_temps.end ) },
								   item_emploi_du_temps.cours,
								   item_emploi_du_temps.devoirs );
		      };

		      $scope.extract_classes_promises = function( data ) {
			  return _.chain( data )
			      .pluck( 'regroupement_id' )
			      .uniq()
			      .map( function( regroupement_id ) {
				  return Annuaire.get_regroupement( regroupement_id );
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

		      $scope.types_de_devoir = API.query_types_de_devoir();

		      // population des créneaux d'emploi du temps avec les cours et devoirs éventuels

		      // API.query_emplois_du_temps().then( function(response) {
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

			  $scope.loading = false;
		      });
		  } ] );
