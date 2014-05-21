'use strict';

angular.module('cahierDeTexteApp')
    .controller('EnseignantCtrl',
		[ '$scope', '$modal', '$q', '$filter', 'CALENDAR_OPTIONS', 'CALENDAR_PARAMS', 'TINYMCE_OPTIONS', 'API', 'Annuaire', 'Documents', 'Cours', 'Devoirs', 'EmploisDuTemps', 'CreneauEmploiDuTemps', 'User',
		  function ( $scope, $modal, $q, $filter, CALENDAR_OPTIONS, CALENDAR_PARAMS, TINYMCE_OPTIONS, API, Annuaire, Documents, Cours, Devoirs, EmploisDuTemps, CreneauEmploiDuTemps, User ) {
		      $scope.types_de_devoir = API.query_types_de_devoir();
		      $scope.matieres = [];
		      $scope.classes = [];
		      $scope.classe = null;

		      var ouvre_popup_edition = function( popup_callback ) {
			  $modal.open({ templateUrl: 'app/views/enseignant/detail_emploi_du_temps.html',
					resolve: { raw_data: function() { return $scope.raw_data; },
						   types_de_devoir: function() { return $scope.types_de_devoir; },
						   matieres: function() { return $scope.matieres; },
						   classes: function() { return $scope.classes; },

						   creneau_emploi_du_temps_id: function() { return $scope.creneau.details.creneau_emploi_du_temps_id; },
						   matiere_id: function() { return $scope.matiere_id; },
						   regroupement_id: function() { return $scope.regroupement_id; },

						   cours: function() { return $scope.cours; },
						   devoirs: function() { return $scope.devoirs; }
						 },
					controller: [ '$scope', '$filter', 'TINYMCE_OPTIONS', '$modalInstance',
						      'CreneauEmploiDuTemps', 'Documents', 'cours', 'devoirs', 'types_de_devoir',
						      'creneau_emploi_du_temps_id', 'matiere_id', 'regroupement_id',
						      'raw_data', 'classes', 'matieres',
						      function( $scope, $filter, TINYMCE_OPTIONS, $modalInstance, CreneauEmploiDuTemps, Documents, cours, devoirs, types_de_devoir, creneau_emploi_du_temps_id, matiere_id, regroupement_id, raw_data, classes, matieres ) {
							  // Attention, $scope ici est le scope de la popup, plus celui d'EnseignantCtrl !
							  $scope.matieres_ary = _($scope.matieres).values();

							  if ( creneau_emploi_du_temps_id === undefined ){
							      $scope.creneau = CreneauEmploiDuTemps.get({ id: creneau_emploi_du_temps_id });
							  }

							  $scope.dirty = false;
							  $scope.deleted = false;
							  $scope.is_dirty = function() {
							      $scope.dirty = true;
							  };
							  $scope.cartable = [];

							  Documents.list_files(  ).success( function( response ) {
							      $scope.cartable = response.data;
							      $scope.cartable.files = _.chain( $scope.cartable.files )
								  .rest()
								  .value()
								  .map( function( elt ) {
								      elt.children = [];
								      return elt;
								  } );
							  } );

							  //;;;;;;;;;;;;;;;;;;;;;;;
							  $scope.remove_ressource = function( item, hash ) {
							      item.ressources = _(item.ressources).reject( function( ressource ) {
								  return ressource.hash == hash;
							      } );
							      $scope.dirty = true;
							  };

							  $scope.treeClicked = function( item, noeud ) {
							      if ( noeud.mime === 'directory' ) {
								  Documents.list_files( noeud.hash ).then( function( response ) {
								      _.chain( response.data.files )
									  .rest()
									  .each( function( elt ) {
									      elt.children = [];
									      noeud.children.push( elt );
									  } );
								  } );
							      } else {
								  if ( _(item.ressources).findWhere( { hash: noeud.hash } ) === undefined ) {
								      item.ressources.push( { name: noeud.name,
											       hash: noeud.hash } );
								      $scope.dirty = true;
								  }
							      }
							  };
							  $scope.treeOptions = {
							      nodeChildren: "children",
							      dirSelectable: true
							  };
							  //;;;;;;;;;;;;;;;;;;;;;;;

							  var create_devoir = function( cours ) {
							      var devoir = new Devoirs({ cours_id: cours.id,
											 date_due: new Date().toISOString(),
											 type_devoir_id: null,
											 creneau_emploi_du_temps_id: null });
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
							      $modalInstance.close( { dirty: $scope.dirty,
										      deleted: $scope.deleted,
										      cours: $scope.cours,
										      devoirs: $scope.devoirs,
										      matiere_id: $scope.matiere_id,
										      regroupement_id: $scope.regroupement_id } );
							  };

							  $scope.effacer = function() {
							      $scope.cours.$delete();
							      _($scope.devoirs).each( function( devoir ) {
								  devoir.$delete();
							      });
							      $scope.deleted = false;

							      $scope.fermer();
							  };

							  $scope.annuler = function() {
							      $scope.dirty = false;
							      $scope.fermer();
							  };

							  $scope.valider = function() {
							      // réinitialisation des erreurs
							      $scope.erreurs = [];

							      if ( $scope.matiere_id !== '' && $scope.regroupement_id !== '' ) {
								  // traitement de la séquence pédagogique
								  var promesse = $q.when( true );
								  if ( _($scope.cours).has( 'contenu' ) && ( $scope.cours.contenu.length > 0 ) ) {
								      $scope.cours.dirty = true;

								      // FIXME: à refactoré
								      if ( $scope.cours.cahier_de_textes_id === null ) {
									  $scope.cours.cahier_de_textes_id = _($scope.classes).findWhere({id: $scope.regroupement_id}).cahier_de_textes_id;
								      }
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

										  // recalcul de la date_due
										  devoir.date_due = _(raw_data).findWhere({creneau_emploi_du_temps_id: devoir.creneau_emploi_du_temps_id}).start;

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
							  $scope.matiere_id = matiere_id.length > 0 ? matiere_id : _.chain($scope.matieres).values().first().value().id;
							  $scope.regroupement_id = regroupement_id.length > 0 ? regroupement_id : $scope.classes[ 0 ].id;
							  $scope.classe = _($scope.classes).findWhere({id: parseInt( $scope.regroupement_id )});
							  $scope.matiere = $scope.matieres[ $scope.matiere_id ];

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
					     objets.devoirs = _(objets.devoirs).filter( function( devoir ) {
						 return _(devoir).has( 'id' );
					     } );

					     popup_callback( objets );
					 } );
		      };

		      // consommation des données //////////////////////////////
		      // helper
		      var update_fullCalendar_event = function( event, cours, devoirs ) {
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

			  if ( cours.deleted ) {
			      return calendar_event = { details: { matiere_id: event.details.matiere_id,
								   regroupement_id: event.details.regroupement_id,
								   cahier_de_textes_id: event.details.cahier_de_textes_id,
								   creneau_emploi_du_temps_id: event.details.creneau_emploi_du_temps_id,
								   cours: {},
								   devoirs: [] },
							allDay: false,
							title: '',
							description: '',
							regroupement: '',
							start: event.start,
							end: event.end,
							className: 'clickable-event'};

			  } else {
			      var calendar_event = { details: { matiere_id: event.details.matiere_id,
								regroupement_id: event.details.regroupement_id,
								cahier_de_textes_id: event.details.cahier_de_textes_id,
								creneau_emploi_du_temps_id: event.details.creneau_emploi_du_temps_id,
								cours: cours,
								devoirs: devoirs },
						     allDay: false,
						     title: '',
						     description: '',
						     regroupement: '',
						     start: event.start,
						     end: event.end,
						     className: 'clickable-event'};

			      // choix de la couleur
			      if ( cours.contenu === undefined || cours.contenu.length == 0 )  {
				  calendar_event.className += ' saisie-vide';
			      } else {
				  if ( devoirs.length > 0 ) {
				      calendar_event.className += ' saisie-devoirs';
				  } else {
				      if ( cours.date_validation != null ) {
					  calendar_event.className += ' saisie-valide';
				      } else {
					  calendar_event.className += ' saisie-invalide';
				      }
				  }
			      }

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
				  calendar_event.title = $scope.matieres[ event.details.matiere_id ].libelle_long;
			      }

			      return calendar_event;
			  }
		      };

		      var assemble_fullCalendar_event = function( item_emploi_du_temps ) {
			  return update_fullCalendar_event( { details: { matiere_id: item_emploi_du_temps.matiere_id,
										regroupement_id: item_emploi_du_temps.regroupement_id,
										cahier_de_textes_id: item_emploi_du_temps.cahier_de_textes_id,
										creneau_emploi_du_temps_id: item_emploi_du_temps.creneau_emploi_du_temps_id },
								     start: item_emploi_du_temps.start,
								     end: item_emploi_du_temps.end },
								   item_emploi_du_temps.cours,
								   item_emploi_du_temps.devoirs );
		      };

		      var list_classes = function( user ) {
			  return _.chain( user.classes )
			      .reject( function( classe ) {
				  return classe.etablissement_code !== user.profil_actif.uai;
			      })
			      .pluck( 'regroupement_id' )
			      .uniq()
			      .map( function( regroupement_id ) {
				  return Annuaire.get_regroupement( regroupement_id );
			      })
			      .value();
		      };

		      var list_matieres = function( user ) {
			  return _.chain( user.classes )
			      .reject( function( classe ) {
				  return classe.etablissement_code !== user.profil_actif.uai || classe.matiere_enseignee_id === undefined;
			      })
			      .pluck( 'matiere_enseignee_id' )
			      .uniq()
			      .map( function( matiere_id ) {
				  return [ matiere_id, Annuaire.get_matiere( matiere_id ) ];
			      })
			      .object()
			      .value();
		      };

		      var process_data = function() {
			  var filtered_data = $scope.raw_data;

			  // Filtrage sur une seule classe
			  if ( $scope.classe != null ) {
			      filtered_data = _($scope.raw_data).filter( function( creneau ) {
				  return creneau.regroupement_id == $scope.classe;
			      });
			  }

			  $scope.calendar.events[0] = _(filtered_data).map( function( event ) {
			      return assemble_fullCalendar_event( event );
			  } );
		      };

		      var retrieve_data = function( from_date, to_date ) {
			  User.get_user().then( function( response ) {
			      $scope.current_user = response.data;

			      EmploisDuTemps.query(
				  { debut: from_date,
				    fin: to_date,
				    uai: $scope.current_user.profil_actif.uai },
				  function( response ) {
				      $scope.raw_data = response;
				      // Extraction des matières
				      $scope.matieres = list_matieres( $scope.current_user );

				      // Extraction des classes
				      $scope.classes = list_classes( $scope.current_user );

				      $q.all( $scope.matieres, $scope.classes ).then( function(  ) {
					  _($scope.classes).each( function( classe) {
					      classe.libelle = (classe.libelle === null && classe.libelle_aaf !== null) ? classe.libelle_aaf : classe.libelle;
					      classe.libelle_aaf = (classe.libelle_aaf === null && classe.libelle !== null) ? classe.libelle : classe.libelle_aaf;
					  } );

					  // s'il y a des classes et des matières le calendrier est éditable (?)
					  $scope.calendar.options.editable = $scope.classes.length > 0 && _($scope.matieres).size() > 0;

					  process_data();
				      } );
				  } );
			  } );
		      };

		      var create_cours = function( creneau ) {
			  var cours = new Cours({
			      cahier_de_textes_id: creneau.cahier_de_textes_id,
			      creneau_emploi_du_temps_id: creneau.id,
			      date_cours: new Date( creneau.heure_debut ).toISOString()
			  });
			  cours.create = true;

			  return cours;
		      };

		      // configuration du composant calendrier /////////////////
		      $scope.calendar = { options: CALENDAR_OPTIONS,
					  events: [  ] };

		      $scope.calendar.options.eventRender = function( event, element ) {
			  // FIXME: manipulation du DOM dans le contrôleur, sale
			  element.find('.fc-event-title').append( ' - ' + event.regroupement + '<br>' + event.description );
		      };

		      $scope.calendar.options.viewRender = function( view, element ) {
			  retrieve_data( view.visStart, view.visEnd );
		      };

		      // édition d'un créneau existant
		      $scope.calendar.options.eventClick = function( event ) {
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
					  ouvre_popup_edition( function popup_callback( popup_output ) {
					      var updated_event = update_fullCalendar_event( $scope.creneau, popup_output.cours, popup_output.devoirs );

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
					  });
				      });
			      });
		      };

		      // création d'un nouveau créneau
		      $scope.calendar.options.select = function( start, end, allDay ) {
			  var timezoneOffset = new Date(start).getTimezoneOffset() * 60000;
			  $scope.creneau = new CreneauEmploiDuTemps( {  regroupement_id: '',
									jour_de_la_semaine: start.getDay() + 1,
									heure_debut: new Date( new Date(start) - timezoneOffset ).toISOString(),
									heure_fin: new Date( new Date(end) - timezoneOffset ).toISOString(),
									matiere_id: ''
								     } );

			  $scope.creneau.$save()
			      .then( function() {
				  $scope.creneau.dirty = true;
				  $scope.creneau.heure_debut = start;
				  $scope.creneau.heure_fin = end;

				  // durent le $scope.creneau.$save() on perds regroupement_id
				  $scope.creneau.regroupement_id = '';
				  $scope.creneau.cahier_de_textes_id = $scope.classes[0].cahier_de_textes_id,

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
					  ouvre_popup_edition( function popup_callback( popup_output ) {
					      if ( popup_output.dirty ) {
						  $scope.creneau.matiere_id = popup_output.matiere_id;
						  $scope.creneau.regroupement_id = popup_output.regroupement_id;
						  $scope.creneau.cahier_de_textes_id = popup_output.cours.cahier_de_textes_id;
						  $scope.creneau.$update();

						  var iedt = { cours: popup_output.cours,
							       devoirs: popup_output.devoirs,
							       cahier_de_textes_id: popup_output.cours.cahier_de_textes_id,
							       creneau_emploi_du_temps_id: popup_output.cours.creneau_emploi_du_temps_id,
							       matiere_id: popup_output.matiere_id,
							       regroupement_id: popup_output.regroupement_id,
							       start: $scope.creneau.heure_debut,
							       end: $scope.creneau.heure_fin };

						  $scope.calendar.events[0].push( assemble_fullCalendar_event( iedt ) );
						  $scope.emploi_du_temps.fullCalendar( 'renderEvent', _($scope.calendar.events[0]).last(), true );
					      } else {
						  $scope.creneau.$delete(); //full stop
					      }
					  } );
				      } );

				  $scope.emploi_du_temps.fullCalendar('unselect');
			      } );
		      };
		  } ] );
