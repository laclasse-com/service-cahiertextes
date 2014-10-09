'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('EmploiDuTempsCtrl',
		[ '$scope', '$q', '$filter',
		  'CALENDAR_OPTIONS', 'CALENDAR_PARAMS', 'APP_PATH', 'API', 'Annuaire', 'EmploisDuTemps', 'PopupsCreneau', 'CreneauEmploiDuTemps',
		  'current_user',
		  function ( $scope, $q, $filter,
			     CALENDAR_OPTIONS, CALENDAR_PARAMS, APP_PATH, API, Annuaire, EmploisDuTemps, PopupsCreneau, CreneauEmploiDuTemps,
			     current_user ) {
				 $scope.current_user = current_user;

				 var popup_ouverte = false;
				 var filter_data = angular.identity;
				 $scope.scope = $scope;

				 $scope.selected_regroupement_id = undefined;

				 var popup_callback = function( scope_popup ) {
				     var view = $scope.emploi_du_temps.fullCalendar( 'getView' );
				     retrieve_data( view.visStart, view.visEnd );
				 };

				 // consommation des données
				 var populate_calendar = function( filtered_data ) {
				     var CalendarEvent = function( event ) {
					 var _this = this; //pour pouvoir le référencé dans les .then()
					 this.details = event;
					 this.allDay = false;
					 this.title = '';
					 this.regroupement = _($scope.current_user.profil_actif.classes).findWhere({ id: parseInt( this.details.regroupement_id ) });
					 this.has_resources = _(event.cours).has( 'ressources' ) && event.cours.ressources.length > 0;
					 this.temps_estime = 0;
					 _(event.devoirs).each( function( devoir ) {
					     _this.has_ressources = _this.has_ressources && _(devoir).has( 'ressources' ) && devoir.ressources.length > 0;
					     if ( !_(devoir.temps_estime).isNull() ) {
						 _this.temps_estime += devoir.temps_estime;
						 if ( _this.temps_estime > 15 ) {
						     _this.temps_estime = 15;
						 }
					     }
					 } );
					 this.start = new Date( event.start );
					 this.end = new Date( event.end );
					 this.className = 'saisie-vide';

					 Annuaire.get_matiere( event.matiere_id ).$promise.then( function success( response ) {
					     if ( _(response.libelle_long).isUndefined() ) {
						 _this.title += event.matiere_id;
					     } else {
						 _this.title += response.libelle_long;
					     }
					 } );

					 if ( event.devoirs.length > 0 ) {
					     this.className = _( _(event.devoirs).pluck( 'fait' ) ).contains( true ) ? 'edt-devoir-fait' : 'edt-devoir-a-faire';
					     if ( this.className == 'edt-devoir-a-faire' ) {
						 var types_de_devoirs_a_faire = _(event.devoirs).pluck( 'type_devoir_id' );
						 if ( _(types_de_devoirs_a_faire).contains( 2 ) ) { // TypeDevoir[2] est un DM
						     this.className = 'edt-devoir-note-maison';
						 } else if ( _(types_de_devoirs_a_faire).contains( 1 ) ) { // TypeDevoir[1] est un DS
						     this.className = 'edt-devoir-note-surveille';
						 }
					     }
					 } else {
					     this.className = 'edt-cours';
					     if ( !_(event.cours).isNull() ) {
						 this.className += '-saisie';
						 if ( !_(event.cours.date_validation).isNull() && $scope.current_user.profil_actif.type === 'ENS' ) {
						     this.className += '-valide';
						 }
					     }
					 }

					 if ( ( ( $scope.current_user.profil_actif.type === 'ELV' || $scope.current_user.profil_actif.type === 'TUT' ) && _(event.cours).isNull() && _(event.devoirs).isEmpty() ) ) {
					     this.className += ' unclickable-event';
					 } else {
					     this.className += ' clickable-event';
					 }
				     };

				     $scope.calendar.events[ 0 ] = _.chain( filtered_data )
					 .map( function( event ) {
					     return new CalendarEvent( event );
					 } )
					 .value();
				 };

				 $scope.refresh_calendar = function(  ) {
				     $scope.calendar.options.weekends = $scope.current_user.parametrage_cahier_de_textes.affichage_week_ends;
				     populate_calendar( filter_data( $scope.raw_data ) );
				 };

				 var retrieve_data = function( from_date, to_date ) {
				     EmploisDuTemps.query( { debut: from_date,
							     fin: to_date,
							     uai: $scope.current_user.profil_actif.uai,
							     uid: $scope.current_user.profil_actif.type == 'TUT' ? $scope.current_user.enfant_actif.enfant.id_ent : null } )
					 .$promise
					 .then( function success( response ) {
					     $scope.raw_data = response;
					     $scope.refresh_calendar();
					 });
				 };

				 // configuration du composant calendrier
				 $scope.calendar = { options: CALENDAR_OPTIONS,
						     events: [  ] };

				 $scope.calendar.options.viewRender = function( view, element ) {
				     $scope.current_user.date = view.visStart;
				     retrieve_data( view.visStart, view.visEnd );
				 };

				 $scope.calendar.options.eventRender = function ( event, element ) {
				     // FIXME: manipulation du DOM dans le contrôleur, sale, mais obligé pour l'interprétation du HTML ?
				     var title_element = element.find( '.fc-event-title' );

				     if ( $scope.current_user.profil_actif.classes.length > 0 ) {
					 var regroupement = event.regroupement !== 'undefined' ? event.regroupement.libelle : '';
					 title_element.prepend( regroupement + ' - ' );
				     }
				     if ( $scope.current_user.profil_actif.type !== 'ELV' ) {
					 var inner_element = element.find( '.fc-event-inner' );
					 if ( event.temps_estime > 0 ) {
					     var class_couleur = '';
					     if (event.temps_estime  < 4 ) {
						 class_couleur = ' label-success';
					     } else if (event.temps_estime  < 8 ) {
						 class_couleur = ' label-info';
					     } else if (event.temps_estime  < 12 ) {
						 class_couleur = ' label-warning';
					     } else if (event.temps_estime  <= 15 ) {
						 class_couleur = ' label-danger';
					     }
					     inner_element.prepend( '<div class="est-time est-time-' + event.temps_estime + class_couleur + '"></div>' );
					 }
				     }
				 };

				 $scope.calendar.options.weekends = $scope.current_user.parametrage_cahier_de_textes.affichage_week_ends;

				 var filter_by_regroupement = function( raw_data, selected_regroupement_id ) {
				     return ( _($scope.selected_regroupement_id).isUndefined() || _($scope.selected_regroupement_id).isNull() ) ? raw_data : _( raw_data ).filter( function( creneau ) {
					 return creneau.regroupement_id == selected_regroupement_id;
				     } );
				 };
				 var filter_by_enseignant_id = function( raw_data, uid, active ) {
				     return !active ? raw_data : _( raw_data ).filter( function( creneau ) {
					 return creneau.enseignant_id == uid;
				     } );
				 };

				 // ############################## Profile-specific code ##############################################
				 if ( $scope.current_user.profil_actif.type == 'EVS'
				      || $scope.current_user.profil_actif.type == 'DIR' ) {
					  filter_data = function( raw_data ) {
					      var filtered_data = raw_data;

					      // Filtrage sur une seule classe
					      filtered_data = filter_by_regroupement( filtered_data, $scope.selected_regroupement_id );

					      return filtered_data;
					  };

					  $scope.selected_regroupement_id = $scope.current_user.profil_actif.classes[0].id;
				      }
				 if ( $scope.current_user.profil_actif.type == 'ENS' ) {
				     $scope.uniquement_mes_creneaux = true;
				     $scope.calendar.options.selectable = true;
				     $scope.calendar.options.editable = true;

				     filter_data = function( raw_data ) {
					 var filtered_data = raw_data;

					 // Filtrage sur une seule classe
					 filtered_data = filter_by_regroupement( filtered_data, $scope.selected_regroupement_id );

					 filtered_data = filter_by_enseignant_id( filtered_data, $scope.current_user.uid, $scope.uniquement_mes_creneaux );

					 return filtered_data;
				     };

				     // édition d'un créneau existant
				     $scope.calendar.options.eventClick = function ( event ) {
					 if ( !popup_ouverte ) {
					     CreneauEmploiDuTemps.get( { id: event.details.creneau_emploi_du_temps_id } )
						 .$promise
						 .then( function( creneau_selectionne ) {
						     creneau_selectionne.dirty = false;
						     creneau_selectionne.heure_debut = event.start;
						     creneau_selectionne.heure_fin = event.end;
						     creneau_selectionne.regroupement_id = event.details.regroupement_id;

						     PopupsCreneau.edition( $scope.raw_data,
									    $scope.current_user.profil_actif.matieres, $scope.current_user.profil_actif.classes,
									    creneau_selectionne, event.details.cours, event.details.devoirs,
									    popup_callback, popup_ouverte );
						 } );
					 }
				     };

				     // création d'un nouveau créneau
				     // Le regroupement_id peut être null car on n'a pas fait de choix au niveau de la select box des classes sur full_calendar
				     $scope.calendar.options.select = function ( start, end, allDay ) {
					 if ( end - start == 1800000 ) {
					     end = moment( end ).add( 30, 'minutes' ).toDate();
					 }
					 if ( !popup_ouverte ) {
					     // création du créneau avec les bons horaires
					     start = $filter('correctTimeZone')(start);
					     end = $filter('correctTimeZone')(end);
					     var regroupement_id = _($scope.selected_regroupement_id).isNull() ? null : '' + $scope.selected_regroupement_id;
					     var new_creneau = new CreneauEmploiDuTemps( { regroupement_id: regroupement_id,
											   jour_de_la_semaine: start.getDay() + 1,
											   heure_debut: new Date(new Date(start)).toISOString(),
											   heure_fin: new Date(new Date(end)).toISOString(),
											   matiere_id: '' } );

					     new_creneau.$save()
						 .then( function () {
						     new_creneau.dirty = true;
						     new_creneau.heure_debut = start;
						     new_creneau.heure_fin = end;
						     new_creneau.regroupement_id = regroupement_id;

						     PopupsCreneau.edition( $scope.raw_data,
									    $scope.current_user.profil_actif.matieres, $scope.current_user.profil_actif.classes,
									    new_creneau, null, [],
									    popup_callback, popup_ouverte );

						     $scope.emploi_du_temps.fullCalendar( 'unselect' );
						 } );
					 }
				     };
				 }
				 if ( $scope.current_user.profil_actif.type === 'TUT' ) {
				     $scope.uid_enfant_actif = $scope.current_user.enfants[0].enfant.id_ent;
				     $scope.reload_data = popup_callback;
				 }
				 if ( $scope.current_user.profil_actif.type == 'ELV'
				      || $scope.current_user.profil_actif.type == 'TUT'
				      || $scope.current_user.profil_actif.type == 'EVS'
				      || $scope.current_user.profil_actif.type == 'DIR' ) {
					  $scope.calendar.options.eventClick = function( event ) {
					      if ( !popup_ouverte && ( ( event.details.devoirs.length > 0 ) || ( ! _(event.details.cours).isNull() && _(event.details.cours).has( 'contenu' ) ) ) ) {
						  PopupsCreneau.display( event.title, event.details.cours, event.details.devoirs, popup_callback, popup_ouverte );
					      }
					  };
				      }

				 if ( $scope.current_user.date ) {
				     var mdate = moment( $scope.current_user.date );
				     $scope.calendar.options.year = mdate.year();
				     $scope.calendar.options.month = mdate.month();
				     $scope.calendar.options.date = mdate.date();
				 }
			     } ] );
