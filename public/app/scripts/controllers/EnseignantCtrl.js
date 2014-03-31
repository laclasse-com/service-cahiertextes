'use strict';

angular.module('cahierDeTexteApp')
    .controller('EnseignantCtrl',
		[ '$scope', '$modal', '$q', 'THEME', 'CALENDAR_OPTIONS', 'CALENDAR_PARAMS', 'TINYMCE_OPTIONS', 'API', 'Annuaire', 'Cours', 'Devoirs', 'EmploisDuTemps', 'User', 'CreneauEmploiDuTemps',
		  function ( $scope, $modal, $q, THEME, CALENDAR_OPTIONS, CALENDAR_PARAMS, TINYMCE_OPTIONS, API, Annuaire, Cours, Devoirs, EmploisDuTemps, User, CreneauEmploiDuTemps ) {
		      $scope.build_EdT_from_scratch = true;

		      $scope.matieres = [];
		      $scope.classes = [];
		      $scope.classe = null;

		      // configuration du composant calendrier /////////////////
		      $scope.calendar = { options: CALENDAR_OPTIONS,
					  events: [  ] };
		      $scope.calendar.options.defaultView = 'agendaWeek';
		      $scope.calendar.options.eventRender = function( event, element ) {
			  element.find('.fc-event-title').append( ' - ' + event.regroupement );
			  element.find('.fc-event-title').append( '<br>' );
			  element.find('.fc-event-title').append( event.description );
		      };
		      if ( $scope.build_EdT_from_scratch ) {
			  $scope.calendar.options.editable = true;
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

			      $scope.creneau.$save().then(function() {
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

				  $scope.matiere_id = $scope.creneau.matiere_id;
				  $scope.regroupement_id = $scope.creneau.regroupement_id;

				  // 1. cours
				  $scope.cours = create_cours( $scope.creneau );

				  // 2. devoir
				  $scope.devoirs = [];

				  // 3. ouverture de la popup
				  $q.all( $scope.types_de_devoir, $scope.cours, $scope.devoirs )
				      .then( function() {
					  $scope.creneau.details = {  };
					  $scope.creneau.details.cours = $scope.cours;
					  $scope.creneau.details.devoirs = $scope.devoirs;

					  $scope.ouvre_popup_edition(  );
				      });

				  $scope.emploi_du_temps.fullCalendar('unselect');
			      });
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
				  date_cours: new Date( creneau.start ).toISOString()
			      });
			      cours.create = true;

			      return cours;
			  };

			  $scope.creneau = _(event.source.events).findWhere({_id: event._id});
			  $scope.matiere_id = event.details.matiere_id;
			  $scope.regroupement_id = event.details.regroupement_id;

			  // 1. cours
			  if ( $scope.creneau.details.cours.id !== undefined ) {
			      API.get_cours( { id: $scope.creneau.details.cours.id } )
				  .$promise.then( function success( cours ) {
				      $scope.cours = cours;
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
			      $scope.devoirs = [];
			      _($scope.creneau.details.devoirs).each( function( devoir ) {
				  API.get_devoir( { id: $scope.creneau.details.devoirs[0].id } ).$promise
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

		      $scope.calendar.options.viewRender = function( view, element ) {
			  // population des créneaux d'emploi du temps avec les cours et devoirs éventuels
			  $scope.retrieve_data( view.visStart, view.visEnd );
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
					controller: function( $scope, TINYMCE_OPTIONS, $modalInstance, cours, devoirs, types_de_devoir, matiere_id, regroupement_id, raw_data, classes, matieres ) {
					    // Attention, $scope ici est le scope de la popup, plus celui d'EnseignantCtrl !
					    $scope.matieres = matieres;
					    $scope.classes = classes;
					    $scope.cours = cours;
					    $scope.devoirs = devoirs;
					    $scope.types_de_devoir = types_de_devoir;
					    $scope.matiere_id = matiere_id;
					    $scope.regroupement_id = regroupement_id;
					    $scope.tinyMCEOptions = TINYMCE_OPTIONS;

					    $scope.erreurs = [];

					    $scope.dateOptions = {
						'year-format': "'yy'",
						'starting-day': 1
					    };
					    $scope.datePickerOpened = false;
					    $scope.openDatePicker = function($event) {
						$event.preventDefault();
						$event.stopPropagation();

						$scope.opened = true;
					    };

					    // http://stackoverflow.com/questions/19408883/angularjs-select-not-2-way-binding-to-model
					    $scope.scope = $scope;

					    // TODO: à raffiner
					    $scope.creneaux_similaires = _.chain(raw_data)
						.where({matiere_id: $scope.matiere_id})
						.reject(function( creneau ) {
						    return creneau.regroupement_id == $scope.regroupement_id;
						})
						.value();
					    $scope.creneaux_similaires.selected = [];

					    var create_devoir = function( cours ) {
						var date = new Date();
						var devoir = new Devoirs({ cours_id: cours.id,
									   date_due: date.toISOString(), //date.getFullYear() + '-' + date.getMonth() + '-' + date.getDay(),
									   type_devoir_id: null });
						devoir.create = true;

						return devoir;
					    };

					    $scope.ajout_devoir = function() {
						$scope.devoirs.unshift( create_devoir( $scope.cours ) );
					    };

					    $scope.dupliquer = function() {
						_($scope.creneaux_similaires.selected).each( function( creneau_cible ) {
						    var cc = JSON.parse( creneau_cible );
						    $scope.cours.$copie({ regroupement_id: cc.regroupement_id,
									  creneau_emploi_du_temps_id: cc.creneau_emploi_du_temps_id });
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
					} }
				     ).result.then(     // éxécuté à la fermeture de la popup
					 function ( objets ) {
					     var updated_event = {};

					     objets.devoirs = _(objets.devoirs).filter( function( devoir ) {
						 return _(devoir).has( 'id' );
					     } );

					     // s'il s'agit d'une création de créneau
					     if ( ! _($scope.creneau).has( '_id' ) ) {
						 if ( objets.matiere_id === '' || objets.regroupement_id === '' ) { //the user hasn't selected a class and/or matiere
						     $scope.creneau.$delete(); //full stop
						 } else {
						     $scope.creneau.matiere_id = objets.matiere_id;
						     $scope.creneau.regroupement_id = objets.regroupement_id;

						     $scope.creneau.$update();

						     // if ( ( objets.cours.dirty ) || ( objets.devoirs.dirty ) ) {
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
						     // }
						 }
					     } else {

						 if ( ( objets.cours.dirty ) || ( objets.devoirs.dirty ) ) {
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
				  calendar_event.color = THEME.calendar.devoir;
			      } else {
				  if ( cours.date_validation != null ) {
				      calendar_event.color = THEME.validated.base;
				  } else {
				      calendar_event.color = THEME.calendar.saisie;
				  }
			      }
			  } else {
			      calendar_event.color = THEME.calendar.vide;
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
			      calendar_event.regroupement = $scope.classes[ event.details.regroupement_id ];
			  } else {
			      calendar_event.regroupement = '';
			  }

			  if ( event.details.matiere_id.length > 0 ) {
			      $scope.matieres[ event.details.matiere_id ] = Annuaire.get_matiere( event.details.matiere_id );

			      $scope.matieres[ event.details.matiere_id ].$promise.then( function success( response ) {
				  calendar_event.title = $scope.matieres[ event.details.matiere_id ].libelle_long;
			      });
			  }

			  return calendar_event;
		      };

		      $scope.assemble_fullCalendar_event = function( item_emploi_du_temps ) {
			  var timezoneOffset = (new Date( item_emploi_du_temps.start )).getTimezoneOffset() * 60 * 1000 ;
			  var start = item_emploi_du_temps.start;
			  var end = item_emploi_du_temps.end;

			  return $scope.update_fullCalendar_event( { details: { matiere_id: item_emploi_du_temps.matiere_id,
										regroupement_id: item_emploi_du_temps.regroupement_id,
										cahier_de_textes_id: item_emploi_du_temps.cahier_de_textes_id,
										creneau_emploi_du_temps_id: item_emploi_du_temps.creneau_emploi_du_temps_id },
								     start: start,
								     end: end },
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
			  if ( $scope.classe != null ) {
			      // .invert() suppose que les valeurs sont uniques
			      var id = _($scope.classes).invert()[ $scope.classe ];
			      filtered_data = _($scope.raw_data).filter( function( creneau ) {
				  return creneau.regroupement_id == id;
			      });
			  }

			  $scope.calendar.events[0] = _(filtered_data).map( function( event ) {
			      return $scope.assemble_fullCalendar_event( event );
			  } );
		      };

		      $scope.retrieve_data = function( from_date, to_date ) {
			  EmploisDuTemps.query( { debut: from_date,
						  fin: to_date },
						function( response ) {
						    $scope.raw_data = response;

						    // Extraction des classes
						    $q.all( $scope.extract_classes_promises( $scope.raw_data ) )
							.then( function( classes ) {
							    if ( classes.length > 0 ) {
								_(classes).each(function( classe ) {
								    $scope.classes[classe.id] = classe.libelle !== null ? classe.libelle : classe.libelle_aaf;
								});
								$scope.calendar.options.editable = $scope.build_EdT_from_scratch;
							    } else {
								$scope.calendar.options.editable = false;
							    }

							    $scope.process_data();
							});
						} );
		      };

		      $scope.types_de_devoir = API.query_types_de_devoir();
		  } ] );
