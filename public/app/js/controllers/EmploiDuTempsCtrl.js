'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller( 'EmploiDuTempsCtrl',
                 [ '$scope', 'moment', '$stateParams', '$state',
                   'CALENDAR_OPTIONS', 'APP_PATH', 'SEMAINES_VACANCES', 'ZONE', 'EmploisDuTemps', 'PopupsCreneau', 'CreneauxEmploiDuTemps', 'Utils', 'Annuaire',
                   'current_user',
                   function ( $scope, moment, $stateParams, $state,
                              CALENDAR_OPTIONS, APP_PATH, SEMAINES_VACANCES, ZONE, EmploisDuTemps, PopupsCreneau, CreneauxEmploiDuTemps, Utils, Annuaire,
                              current_user ) {
                       $scope.scope = $scope;
                       $scope.current_user = current_user;
                       $scope.zone = ZONE;
                       $scope.emploi_du_temps = angular.element('#emploi_du_temps');
                       var popup_ouverte = false;
                       var first_load = true;

                       $scope.uniquement_mes_creneaux = !_( [ 'EVS', 'DIR'] ).contains( $scope.current_user.profil_actif.type );

                       $scope.filter_data = function( raw_data ) {
                           if ( _( [ 'EVS', 'DIR'] ).contains( $scope.current_user.profil_actif.type ) ) {
                               return filter_by_regroupement( raw_data, $scope.selected_regroupements );
                           } else if ( _( [ 'ENS', 'DOC'] ).contains( $scope.current_user.profil_actif.type ) ) {
                               return filter_by_matieres( filter_by_regroupement( raw_data,
                                                                                  $scope.selected_regroupements ),
                                                          $scope.current_user.extract_subjects_ids(),
                                                          $scope.uniquement_mes_creneaux );
                           } else {
                               return raw_data;
                           }
                       };

                       $scope.prev = function() { $scope.emploi_du_temps.fullCalendar('prev'); };
                       $scope.next = function() { $scope.emploi_du_temps.fullCalendar('next'); };

                       $scope.select_all_regroupements = function() {
                           $scope.selected_regroupements = $scope.current_user.actual_groups;
                           $scope.refresh_calendar();
                       };

                       $scope.select_no_regroupements = function() {
                           $scope.selected_regroupements = [];
                           $scope.refresh_calendar();
                       };

                       var popup_callback = function( scope_popup ) {
                           var view = $scope.emploi_du_temps.fullCalendar( 'getView' );
                           retrieve_data( view.start.toDate(), view.end.toDate() );
                       };

                       // consommation des données
                       var to_fullcalendar_events = function( filtered_data ) {
                           var CalendarEvent = function( event ) {
                               var fc_event = this; //pour pouvoir le référencé dans les .then()
                               fc_event.details = event;
                               fc_event.allDay = false;
                               fc_event.regroupement = _($scope.current_period_groups).findWhere({ id: parseInt( fc_event.details.regroupement_id ) });
                               fc_event.title = ( _(fc_event.regroupement).isUndefined() ) ? '' : fc_event.regroupement.name;
                               fc_event.matiere = _($scope.subjects).findWhere({ id: fc_event.details.matiere_id });
                               fc_event.has_resources = _(event.cours).has( 'ressources' ) && event.cours.ressources.length > 0;
                               fc_event.temps_estime = 0;
                               fc_event.start = moment( event.start );
                               fc_event.end = moment( event.end );
                               fc_event.className = 'saisie-vide';

                               if ( !_(event.cours).isNull() ) {
                                   _(event.cours.devoirs).each( function( devoir ) {
                                       fc_event.has_ressources = fc_event.has_ressources || _(devoir).has( 'ressources' ) && devoir.ressources.length > 0;
                                   } );
                               }

                               _(event.devoirs).each( function( devoir ) {
                                   fc_event.has_ressources = fc_event.has_ressources || _(devoir).has( 'ressources' ) && devoir.ressources.length > 0;
                                   if ( !_(devoir.temps_estime).isNull() ) {
                                       fc_event.temps_estime += devoir.temps_estime;
                                       if ( fc_event.temps_estime > 15 ) {
                                           fc_event.temps_estime = 15;
                                       }
                                   }
                               } );

                               // couleur de la case
                               if ( event.devoirs.length > 0 ) {
                                   var highest_type_de_devoir = _.chain(event.devoirs).pluck( 'type_devoir_id' ).sort().first().value();
                                   switch( highest_type_de_devoir ) {
                                   case 1:
                                       fc_event.className = 'edt-devoir-note-surveille';
                                       break;
                                   case 2:
                                       fc_event.className = 'edt-devoir-note-maison';
                                       break;
                                   default:
                                       fc_event.className = _.chain(event.devoirs).pluck( 'fait' ).contains( true ).value() ? 'edt-devoir-fait' : 'edt-devoir-a-faire';
                                   }
                               } else {
                                   fc_event.className = 'edt-cours';
                                   if ( !_(event.cours).isNull() && !_(event.cours.date_validation).isNull() && ( $scope.current_user.profil_actif.type === 'ENS' && $scope.current_user.profil_actif.type === 'DOC' ) ) {
                                       fc_event.className += '-valide';
                                   } else if ( !_(event.cours).isNull() ) {
                                       fc_event.className += '-saisie';
                                   }
                               }

                               if ( ( ( _( [ 'ELV', 'TUT', 'EVS', 'DIR'] ).contains( $scope.current_user.profil_actif.type ) ) && _(event.cours).isNull() && _(event.devoirs).isEmpty() ) ) {
                                   fc_event.className += ' unclickable-event';
                               } else {
                                   fc_event.className += ' clickable-event';
                               }
                           };

                           return _( filtered_data ).map( function( event ) {
                               return new CalendarEvent( event );
                           } );
                       };

                       $scope.refresh_calendar = function() {
                           $scope.calendar.events[ 0 ] = to_fullcalendar_events( $scope.filter_data( $scope.raw_data ) );

                           // $stateParams.regroupements = _($scope.selected_regroupements).pluck('name');
                           // $state.go( $state.current, $stateParams, { notify: false, reload: false } );
                       };

                       var retrieve_data = function( from_date, to_date ) {
                           if ( $scope.current_user.profil_actif.type != 'TUT' || $scope.current_user.enfant_actif ) {
                               EmploisDuTemps.query( { debut: from_date,
                                                       fin: to_date,
                                                       uai: $scope.current_user.profil_actif.structure_id,
                                                       uid: $scope.current_user.profil_actif.type == 'TUT' ? $scope.current_user.enfant_actif.enfant.id_ent : null } )
                                   .$promise
                                   .then( function success( response ) {
                                       // $stateParams.date = moment( from_date ).toDate().toISOString().split('T')[0];
                                       // $state.go( $state.current, $stateParams, { notify: false, reload: false } );

                                       $scope.raw_data = response;
                                       var groups_ids = _.chain($scope.raw_data).pluck('regroupement_id').uniq().value();
                                       var subjects_ids = _.chain($scope.raw_data).pluck('matiere_id').uniq().value();

                                       Annuaire.get_groups( groups_ids )
                                           .then( function( response ) {
                                               $scope.current_period_groups = response.data;

                                               return Annuaire.get_subjects( subjects_ids );
                                           } )
                                           .then( function( response ) {
                                               // $scope.subjects = _(response.data).indexBy('id');
                                               $scope.subjects = response.data;

                                               $scope.refresh_calendar();
                                           } );
                                   });
                           }
                       };

                       // configuration du composant calendrier
                       $scope.current_user.get_actual_groups()
                           .then( function( actual_groups ) {
                               if ( $scope.uniquement_mes_creneaux ) {
                                   $scope.selected_regroupements = $scope.current_user.actual_groups;
                               } else {
                                   $scope.selected_regroupements = [ $scope.current_user.actual_groups[0] ];
                               }
                           } );


                       $scope.extraEventSignature = function( event ) {
                           return '' + event.matiere;
                       };

                       var filter_by_regroupement = function( raw_data, selected_regroupements ) {
                           return _( raw_data ).filter( function( creneau ) {
                               return _.chain(selected_regroupements).pluck('id').contains( parseInt( creneau.regroupement_id ) ).value();
                           } );
                       };
                       var filter_by_matieres = function( raw_data, subjects_ids, active ) {
                           return !active ? raw_data : _( raw_data ).filter( function( creneau ) {
                               return _(subjects_ids).contains( creneau.matiere_id );
                           } );
                       };

                       // Les TUT peuvent choisir parmi leurs enfants
                       if ( $scope.current_user.profil_actif.type === 'TUT' ) {
                           if ( $scope.current_user.enfants.length == 0 ) {
                               swal( { title: 'Erreur',
                                       text: 'Aucun enfant configuré pour ce profil.',
                                       type: 'error',
                                       showCancelButton: false,
                                       confirmButtonColor: '#ff6b55',
                                       confirmButtonText: 'Fermer'
                                     } );
                           } else {
                               $scope.uid_enfant_actif = $scope.current_user.enfant_actif.enfant.id_ent;
                               $scope.reload_data = popup_callback;
                           }
                       }

                       $scope.calendar = { options: CALENDAR_OPTIONS,
                                           events: [  ] };

                       // Les (ENS|DOC) et les Admin sont en lecture/écriture
                       if ( _( [ 'ENS', 'DOC'] ).contains( $scope.current_user.profil_actif.type )
                            || $scope.current_user.profil_actif.admin ) {
                           $scope.calendar.options.selectable = true;
                           $scope.calendar.options.editable = true;
                           $scope.calendar.options.eventDurationEditable = true;
                           $scope.calendar.options.eventStartEditable = true;
                       }

                       $scope.calendar.options.weekends = $scope.current_user.parametrage_cahier_de_textes.affichage_week_ends;

                       $scope.calendar.options.viewRender = function( view, element ) {
                           $scope.current_user.date = view.start;
                           $scope.n_week = view.start.week();
                           $scope.c_est_les_vacances = Utils.sont_ce_les_vacances( $scope.n_week, $scope.zone );

                           retrieve_data( view.start.toDate(), view.end.toDate() );
                       };

                       $scope.calendar.options.eventRender = function ( event, element ) {
                           // FIXME: manipulation du DOM dans le contrôleur, sale, mais obligé pour l'interprétation du HTML ?
                           var elt_fc_content_title = element.find( '.fc-title' );
                           var elt_fc_content = element.find( '.fc-content' );

                           if ( !_(event.matiere).isUndefined() ) {
                               elt_fc_content_title.append( ' - ' + event.matiere.name );
                           }

                           if ( event.has_resources ) {
                               elt_fc_content.prepend( '<i class="glyphicon glyphicon-paperclip"></i>' );
                           }
                           if ( $scope.current_user.profil_actif.type !== 'ELV' ) {
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
                                   elt_fc_content.prepend( '<div class="est-time est-time-' + event.temps_estime + class_couleur + '"></div>' );
                               }
                           }
                       };

                               $scope.calendar.options.eventClick = function( event ) {
                           if ( _( [ 'ENS', 'DOC' ] ).contains( $scope.current_user.profil_actif.type ) || $scope.current_user.profil_actif.admin ) {
                               if ( !popup_ouverte ) {
                                   CreneauxEmploiDuTemps.get( { id: event.details.creneau_emploi_du_temps_id } )
                                       .$promise
                                       .then( function( creneau_selectionne ) {
                                           creneau_selectionne.dirty = false;
                                           creneau_selectionne.en_creation = false;
                                           creneau_selectionne.heure_debut = event.start;
                                           creneau_selectionne.heure_fin = event.end;
                                           creneau_selectionne.regroupement_id = event.details.regroupement_id;

                                           PopupsCreneau.edition( $scope.raw_data,
                                                                  $scope.subjects, $scope.current_period_groups,
                                                                  creneau_selectionne, event.details.cours, event.details.devoirs,
                                                                  popup_callback, popup_ouverte );
                                       } );
                               }
                           } else {
                               if ( !popup_ouverte && ( ( event.details.devoirs.length > 0 ) || ( ! _(event.details.cours).isNull() && _(event.details.cours).has( 'contenu' ) ) ) ) {
                                   PopupsCreneau.display( event.matiere,
                                                          event.details.cours,
                                                          event.details.devoirs,
                                                          popup_callback,
                                                          popup_ouverte );
                               }
                           }
                       };

                       // création d'un nouveau créneau
                       // Le regroupement_id peut être null car on n'a pas fait de choix au niveau de la select box des classes sur full_calendar
                       $scope.calendar.options.select = function ( start, end, allDay ) {
                           if ( $scope.calendar.options.selectable && $scope.calendar.options.editable ) {
                               if ( end - start == 1800000 ) {
                                   end = moment( end ).add( 30, 'minutes' ).toDate();
                               }
                               if ( !popup_ouverte ) {
                                   // création du créneau avec les bons horaires
                                   start = new Date( start );
                                   end = new Date( end );
                                   var regroupement_id = $scope.selected_regroupements.length == 1 ? '' + $scope.selected_regroupements[0].id : null;
                                   var new_creneau = new CreneauxEmploiDuTemps( { regroupement_id: regroupement_id,
                                                                                  jour_de_la_semaine: start.getDay(),
                                                                                  heure_debut: moment(start).toISOString(),
                                                                                  heure_fin: moment(end).toISOString(),
                                                                                  matiere_id: '' } );

                                   new_creneau.$save()
                                       .then( function () {
                                           new_creneau.dirty = true;
                                           new_creneau.en_creation = true;
                                           new_creneau.heure_debut = start;
                                           new_creneau.heure_fin = end;
                                           new_creneau.regroupement_id = regroupement_id;

                                           PopupsCreneau.edition( $scope.raw_data,
                                                                  $scope.current_user.profil_actif.matieres, $scope.current_user.profil_actif.regroupements,
                                                                  new_creneau, null, [],
                                                                  popup_callback, popup_ouverte );

                                           $scope.emploi_du_temps.fullCalendar( 'unselect' );
                                       } );
                               }
                           }
                       };

                       $scope.calendar.options.eventDrop = function( event, delta, revertFunc, jsEvent, ui, view ) {
                           if ( $scope.calendar.options.selectable && $scope.calendar.options.editable ) {
                               CreneauxEmploiDuTemps.update( { id: event.details.creneau_emploi_du_temps_id,
                                                               heure_debut: event.start.toDate(),
                                                               heure_fin: event.end.toDate(),
                                                               jour_de_la_semaine: event.end.day() } );
                           }
                       };
                       $scope.calendar.options.eventResize = function( event, delta, revertFunc, jsEvent, ui, view ) {
                           if ( $scope.calendar.options.selectable && $scope.calendar.options.editable ) {
                               CreneauxEmploiDuTemps.update( { id: event.details.creneau_emploi_du_temps_id,
                                                               heure_debut: event.start.toDate(),
                                                               heure_fin: event.end.toDate() } );
                           }
                       };
                   } ] );
