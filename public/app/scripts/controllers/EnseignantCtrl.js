'use strict';

angular.module('cahierDeTexteApp')
    .controller('EnseignantCtrl',
		[ '$scope', '$modal', '$q', '$filter', 'CALENDAR_OPTIONS', 'CALENDAR_PARAMS', 'TINYMCE_OPTIONS', 'API', 'Annuaire', 'Cours', 'Devoirs', 'EmploisDuTemps', 'CreneauEmploiDuTemps', 'User',
		  function ( $scope, $modal, $q, $filter, CALENDAR_OPTIONS, CALENDAR_PARAMS, TINYMCE_OPTIONS, API, Annuaire, Cours, Devoirs, EmploisDuTemps, CreneauEmploiDuTemps, User ) {
		      $scope.types_de_devoir = API.query_types_de_devoir();
		      $scope.matieres = [];
		      $scope.classes = [];
		      $scope.classe = null;

		      // configuration du composant calendrier /////////////////
		      $scope.calendar = { options: CALENDAR_OPTIONS,
					  events: [  ] };
		      $scope.calendar.options.defaultView = 'agendaWeek';
		      $scope.calendar.options.eventRender = function( event, element ) {
			  // FIXME: manipulation du DOM dans le contrôleur, sale
			  element.find('.fc-event-title').append( ' - ' + event.regroupement );
			  element.find('.fc-event-title').append( '<br>' );
			  element.find('.fc-event-title').append( event.description );
		      };

		      $scope.calendar.options.viewRender = function( view, element ) {
			  // population des créneaux d'emploi du temps avec les cours et devoirs éventuels
			  $scope.retrieve_data( view.visStart, view.visEnd );
		      };
		      // // ouverture de la popup de création/édition //////////
		      $scope.calendar.options.eventClick = function( event ) {
			  var create_cours = function( creneau ) {
			      var cours = new Cours({
				  cahier_de_textes_id: creneau.details.cahier_de_textes_id,
				  creneau_emploi_du_temps_id: creneau.details.creneau_emploi_du_temps_id,
				  date_cours: new Date( creneau.start ).toISOString()
			      });
			      cours.create = true;

			      return cours;
			  };

			  $scope.creneau = _(event.source.events).findWhere({_id: event._id});

			  $scope.cours = null;
			  $scope.devoirs = null;
			  $scope.regroupement_id = null;
			  $scope.matiere_id = null;

			  $scope.matiere_id = event.details.matiere_id;
			  $scope.regroupement_id = event.details.regroupement_id;

			  // 1. cours
			  if ( $scope.creneau.details.cours.id !== undefined ) {
			      $scope.cours = API.get_cours( { id: $scope.creneau.details.cours.id } );
			  } else {
			      $scope.cours = create_cours( $scope.creneau );
			  }
			  $q.all( $scope.cours, $scope.types_de_devoir, $scope.matieres, $scope.classes )
			      .then( function() {
				  $scope.devoirs = [];
				  // 2. devoir
				  if ( $scope.creneau.details.devoirs.length > 0 ) {
				      _($scope.creneau.details.devoirs).each( function( devoir ) {
					  API.get_devoir( { id: $scope.creneau.details.devoirs[0].id } ).$promise
					      .then( function( vrai_devoir ) {
						  $scope.devoirs.push( vrai_devoir );
					      } );
				      } );
				      $scope.devoirs.create = false;

				  }

				  // 3. ouverture de la popup
				  $q.all( $scope.devoirs )
				      .then( function() {
					  $scope.ouvre_popup_edition(  );
				      });
			      });
		      };

		      $scope.ouvre_popup_edition = function(  ) {
			  $modal.open({ templateUrl: 'app/views/modals/enseignant/detail_emploi_du_temps.html',
					resolve: { raw_data: function() { return $scope.raw_data; },
						   matieres: function() { return $scope.matieres; },
						   classes: function() { return $scope.classes; },
						   matiere_id: function() { return $scope.matiere_id; },
						   regroupement_id: function() { return $scope.regroupement_id; },
						   cours: function() { return $scope.cours; },
						   devoirs: function() { return $scope.devoirs; },
						   types_de_devoir: function() { return $scope.types_de_devoir; } },
					controller: [ '$scope', '$filter', 'TINYMCE_OPTIONS', '$modalInstance', 'cours', 'devoirs', 'types_de_devoir', 'matiere_id', 'regroupement_id', 'raw_data', 'classes', 'matieres',
						      function( $scope, $filter, TINYMCE_OPTIONS, $modalInstance, cours, devoirs, types_de_devoir, matiere_id, regroupement_id, raw_data, classes, matieres ) {
							  // Attention, $scope ici est le scope de la popup, plus celui d'EnseignantCtrl !

							  var create_devoir = function( cours ) {
							      var date = new Date();
							      var devoir = new Devoirs({ cours_id: cours.id,
											 date_due: date.toISOString(), //date.getFullYear() + '-' + date.getMonth() + '-' + date.getDay(),
											 type_devoir_id: null });
							      devoir.create = true;

							      return devoir;
							  };

							  $scope.openDatePicker = function($event) {
							      $event.preventDefault();
							      $event.stopPropagation();

							      $scope.opened = true;
							  };

							  $scope.ajout_devoir = function() {
							      $scope.devoirs.unshift( create_devoir( $scope.cours ) );
							  };

							  $scope.dupliquer = function() {
							      _($scope.creneaux_similaires.selected).each( function( creneau_cible ) {
								  $scope.cours.$copie({ regroupement_id: creneau_cible.regroupement_id,
											creneau_emploi_du_temps_id: creneau_cible.creneau_emploi_du_temps_id });
							      });
							  };

							  $scope.fermer = function() {
							      $modalInstance.close( { cours: $scope.cours,
										      devoirs: $scope.devoirs,
										      matiere_id: $scope.matiere_id,
										      regroupement_id: $scope.regroupement_id } );
							  };

							  $scope.valider = function() {
							      // réinitialisation des erreurs
							      $scope.erreurs = [];

							      if ( $scope.matiere_id !== '' && $scope.regroupement_id !== '' ) {
								  // traitement de la séquence pédagogique
								  var promesse = $q.when( true );
								  if ( _($scope.cours).has( 'contenu' ) && ( $scope.cours.contenu.length > 0 ) ) {
								      $scope.cours.dirty = true;
								      if ( $scope.cours.create ) {
									  promesse = $scope.cours.$save();
								      } else {
									  promesse = $scope.cours.$update();
								      }
								  }

								  promesse.then( function( cours ) {
								      $scope.cours = cours;

								      // traitement des devoirs attachés
								      var promesses = [];
								      $scope.devoirs = _($scope.devoirs).map(
									  function( devoir ) {
									      if ( _(devoir).has( 'contenu' ) && ( devoir.contenu.length > 0 ) ) {
										  devoir.dirty = true;
										  var prom = $q.defer();
										  if ( devoir.create ) {
										      devoir.cours_id = $scope.cours.id;
										      devoir.$save().then( function success( result ) {
											  devoir.id = result.id;
											  prom.resolve( result );
										      }, function( response ) {
											  $scope.erreurs.unshift( { status: response.status,
														    message: response.data.error } );
											  prom.reject( response );
										      });
										  } else {
										      devoir.$update().then( function success( result ) {
											  devoir.id = result.id;
											  prom.resolve( result );
										      }, function( response ) {
											  $scope.erreurs.unshift( { status: response.status,
														    message: response.data.error } );
											  prom.reject( response );
										      });
										  }

										  promesses.push( prom.promise );
									      }
									      return devoir;
									  } );

								      $q.all( promesses ).then( function() {
									  $scope.fermer();
								      });
								  });
							      } else {
								  $scope.erreurs.push( { 'message': 'Aucune matière ou classe défini' } );
							      }
							  };

							  $scope.tinyMCEOptions = TINYMCE_OPTIONS;
							  $scope.cours = cours;
							  $scope.devoirs = devoirs;
							  $scope.types_de_devoir = types_de_devoir;
							  $scope.matieres = matieres;
							  $scope.classes = classes;
							  $scope.matiere_id = matiere_id.length > 0 ? matiere_id : $scope.matieres[ 0 ].id;
							  $scope.regroupement_id = regroupement_id.length > 0 ? regroupement_id : $scope.classes[ 0 ].id;
							  $scope.classe = _($scope.classes).findWhere({id: parseInt( $scope.regroupement_id )});
							  $scope.matiere = _($scope.matieres).findWhere({id: $scope.matiere_id});

							  $scope.erreurs = [];

							  $scope.dateOptions = {
							      'year-format': "'yy'",
							      'starting-day': 1
							  };
							  $scope.datePickerOpened = false;

							  // http://stackoverflow.com/questions/19408883/angularjs-select-not-2-way-binding-to-model
							  $scope.scope = $scope;

							  $scope.creneaux_similaires = _.chain(raw_data)
							      .filter( function( creneau ) {
								  return ( creneau.regroupement_id != $scope.regroupement_id ) && ( creneau.matiere_id == $scope.matiere_id );
							      } )
							      .map( function( creneau ) {
								  creneau.classe = _($scope.classes).findWhere({id: parseInt( creneau.regroupement_id ) });
								  creneau.start_str = $filter('date')( creneau.start, 'short' );
								  creneau.end_str = $filter('date')( creneau.end, 'shortTime' );

								  return creneau;
							      })
							      .value();

							  $scope.creneaux_similaires.selected = [];

							  $scope.creneaux_devoirs_possibles = _.chain(raw_data)
							      .filter( function( creneau ) {
								  return ( creneau.regroupement_id == $scope.regroupement_id ) && ( creneau.matiere_id == $scope.matiere_id );
							      } )
							      .map( function( creneau ) {
								  creneau.classe = _($scope.classes).findWhere({id: parseInt( creneau.regroupement_id ) });
								  creneau.start_str = $filter('date')( creneau.start, 'short' );
								  creneau.end_str = $filter('date')( creneau.end, 'shortTime' );

								  return creneau;
							      })
							      .value();
						      } ]
				      }
				     ).result.then(     // éxécuté à la fermeture de la popup
					 function ( objets ) {
					     var updated_event = {};

					     objets.devoirs = _(objets.devoirs).filter( function( devoir ) {
						 return _(devoir).has( 'id' );
					     } );

					     if ( _($scope.creneau).has( '_id' ) ) {
						 updated_event = $scope.update_fullCalendar_event( $scope.creneau, objets.cours, objets.devoirs );

						 var index = _($scope.calendar.events[0]).indexOf($scope.creneau);
						 _.chain(updated_event)
						     .keys()
						     .reject(function( key ) { //updated_event n'a pas de title
							 return key == "title";
						     })
						     .each( function( propriete ) {
							 $scope.calendar.events[0][ index ][ propriete ] = updated_event[ propriete ];
						     });
						 $scope.emploi_du_temps.fullCalendar( 'renderEvent', $scope.calendar.events[0][ index ] );
					     } else {					     // s'il s'agit d'une création de créneau

						 if ( objets.matiere_id === '' || objets.regroupement_id === '' ) { //the user hasn't selected a class and/or matiere
						     $scope.creneau.$delete(); //full stop
						 } else {
						     $scope.creneau.matiere_id = objets.matiere_id;
						     $scope.creneau.regroupement_id = objets.regroupement_id;

						     $scope.creneau.$update();

						     var iedt = { cours: objets.cours,
								  devoirs: objets.devoirs,
								  cahier_de_textes_id: objets.cours.cahier_de_textes_id,
								  creneau_emploi_du_temps_id: objets.cours.creneau_emploi_du_temps_id,
								  matiere_id: objets.matiere_id,
								  regroupement_id: objets.regroupement_id,
								  start: $scope.creneau.heure_debut,
								  end: $scope.creneau.heure_fin };

						     updated_event = $scope.assemble_fullCalendar_event( iedt );

						     $scope.calendar.events[0].push( updated_event );
						     $scope.emploi_du_temps.fullCalendar( 'renderEvent', _($scope.calendar.events[0]).last(), true );
						 }
					     }
					 } );
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

			  calendar_event.className = 'clickable-event';

			  // choix de la couleur
			  if ( ( cours.contenu !== undefined ) && ( cours.contenu.length > 0 ) ) {
			      if ( devoirs.length > 0 ) {
				  calendar_event.className += ' saisie-devoirs';
			      } else {
				  if ( cours.date_validation != null ) {
				      calendar_event.className += ' saisie-valide';
				  } else {
				      calendar_event.className += ' saisie-invalide';
				  }
			      }
			  } else {
			      calendar_event.className += ' saisie-vide';
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
			      calendar_event.description += '<br><span style="color:' + CALENDAR_PARAMS.couleurs.cours + '">';
			      calendar_event.description += clever_truncate( cours.contenu, CALENDAR_PARAMS.cours_max_length );
			      calendar_event.description += '</span>';
			  }

			  if ( event.details.regroupement_id.length > 0 ) {
			      calendar_event.regroupement = _.chain($scope.classes)
				  .filter( function( classe ) {
				      return classe.id == event.details.regroupement_id;
				  })
				  .pluck( 'libelle_aaf' )
				  .value()[0];
			  } else {
			      calendar_event.regroupement = '';
			  }

			  if ( event.details.matiere_id.length > 0 ) {
			      calendar_event.title = _($scope.matieres).findWhere({id:event.details.matiere_id}).libelle_long;
			  }

			  return calendar_event;
		      };

		      $scope.assemble_fullCalendar_event = function( item_emploi_du_temps ) {
			  return $scope.update_fullCalendar_event( { details: { matiere_id: item_emploi_du_temps.matiere_id,
										regroupement_id: item_emploi_du_temps.regroupement_id,
										cahier_de_textes_id: item_emploi_du_temps.cahier_de_textes_id,
										creneau_emploi_du_temps_id: item_emploi_du_temps.creneau_emploi_du_temps_id },
								     start: item_emploi_du_temps.start,
								     end: item_emploi_du_temps.end },
								   item_emploi_du_temps.cours,
								   item_emploi_du_temps.devoirs );
		      };

		      $scope.list_classes = function(  ) {
			  return _.chain( $scope.current_user.classes )
			      .reject( function( classe ) {
				  return classe.etablissement_code !== $scope.current_user.profil_actif.uai;
			      })
			      .pluck( 'regroupement_id' )
			      .uniq()
			      .map( function( regroupement_id ) {
				  return Annuaire.get_regroupement( regroupement_id ).$promise;
			      })
			      .value();
		      };

		      $scope.process_data = function() {
			  var filtered_data = $scope.raw_data;

			  // Filtrage sur une seule classe
			  if ( $scope.classe != null ) {
			      filtered_data = _($scope.raw_data).filter( function( creneau ) {
				  return creneau.regroupement_id == $scope.classe;
			      });
			  }

			  $scope.calendar.events[0] = _(filtered_data).map( function( event ) {
			      return $scope.assemble_fullCalendar_event( event );
			  } );
		      };

		      $scope.retrieve_data = function( from_date, to_date ) {
			  EmploisDuTemps.query( { debut: from_date,
						  fin: to_date } ).$promise
			      .then( function( response ) {
				  $scope.raw_data = response;

				  // Extraction des matières
				  $scope.matieres = _.chain( $scope.raw_data )
				      .pluck( 'matiere_id' )
				      .uniq()
				      .map( function( matiere_id ) {
					  return Annuaire.get_matiere( matiere_id );
				      })
				      .value();
				  User.get_user().then( function( response ) {
				      $scope.current_user = response.data;
				      // Extraction des classes
				      $q.all( $scope.list_classes(  ) )
					  .then( function( response ) {
					      $scope.classes = response;
					      _($scope.classes).each( function( classe) {
						  classe.libelle = (classe.libelle === null && classe.libelle_aaf !== null) ? classe.libelle_aaf : classe.libelle;
						  classe.libelle_aaf = (classe.libelle_aaf === null && classe.libelle !== null) ? classe.libelle : classe.libelle_aaf;
					      });

					      // s'il y a des classes et des matières le calendrier est éditable (?)
					      $scope.calendar.options.editable = $scope.classes.length > 0 && $scope.matieres.length > 0;

					      if ( $scope.calendar.options.editable ) {
						  $scope.calendar.options.disableDragging = true;
						  $scope.calendar.options.eventDurationEditable = false;
						  $scope.calendar.options.selectable = true;
						  $scope.calendar.options.selectHelper = true;
						  $scope.calendar.options.select = function(start, end, allDay) {
						      var timezoneOffset = new Date(start).getTimezoneOffset() * 60000;
						      $scope.creneau= new CreneauEmploiDuTemps({ regroupement_id: '',
												 jour_de_la_semaine: start.getDay() + 1,
												 heure_debut: new Date( new Date(start) - timezoneOffset ).toISOString(),
												 heure_fin: new Date( new Date(end) - timezoneOffset ).toISOString(),
												 matiere_id: ''
											       });

						      $scope.creneau.$save()
							  .then( function() {
							      $scope.creneau.dirty = true;
							      $scope.creneau.heure_debut = start;
							      $scope.creneau.heure_fin = end;

							      var create_cours = function( creneau ) {
								  var cours = new Cours({ cahier_de_textes_id: '',
											  creneau_emploi_du_temps_id: $scope.creneau.id,
											  date_cours: new Date(start).toISOString()
											});
								  cours.create = true;

								  return cours;
							      };

							      // durent le $scope.creneau.$save() on perds regroupement_id
							      $scope.creneau.regroupement_id = '';

							      $scope.cours = null;
							      $scope.devoirs = null;
							      $scope.regroupement_id = null;
							      $scope.matiere_id = null;

							      $scope.matiere_id = $scope.creneau.matiere_id;
							      $scope.regroupement_id = $scope.creneau.regroupement_id;

							      // 1. cours
							      $scope.cours = create_cours( $scope.creneau );

							      // 2. devoir
							      $scope.devoirs = [];

							      // 3. ouverture de la popup
							      $q.all( $scope.types_de_devoir, $scope.cours )
								  .then( function() {
								      $scope.creneau.details = { cours: $scope.cours,
												 devoirs: $scope.devoirs };
								      $scope.ouvre_popup_edition(  );
								  });

							      $scope.emploi_du_temps.fullCalendar('unselect');
							  });
						  };
					      }

					      $scope.process_data();
					  });
				  });
			      } );
		      };
		  } ] );
