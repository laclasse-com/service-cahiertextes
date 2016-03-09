'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller( 'PopupEditionCtrl',
                 [ '$scope', '$filter', '$q', '$sce', '$uibModalInstance', '$locale', 'toastr',
                   'APP_PATH', 'DOCS_URL', 'SEMAINES_VACANCES', 'ZONE', 'POPUP_ACTIONS', 'LOCALHOST',
                   'Documents', 'API', 'CreneauxEmploiDuTemps', 'Cours', 'Devoirs', 'User',
                   'cours', 'devoirs', 'creneau', 'raw_data', 'classes', 'matieres',
                   function ( $scope, $filter, $q, $sce, $uibModalInstance, $locale, toastr,
                              APP_PATH, DOCS_URL, SEMAINES_VACANCES, ZONE, POPUP_ACTIONS, LOCALHOST,
                              Documents, API, CreneauxEmploiDuTemps, Cours, Devoirs, User,
                              cours, devoirs, creneau, raw_data, classes, matieres )
                   {
                       $scope.annee = _($locale.DATETIME_FORMATS.MONTH).toArray();
                       $scope.app_path = APP_PATH;
                       $scope.ZONE = ZONE;

                       $scope.faulty_docs_app = false;

                       $scope.erreurs = [];
                       $scope.dirty = false;
                       $scope.mode_duplication = false;
                       $scope.actions_done = [];

                       // http://stackoverflow.com/questions/19408883/angularjs-select-not-2-way-binding-to-model
                       $scope.scope = $scope;

                       User.get_user().then( function( response ) {
                           $scope.current_user = response.data;

                           var create_cours = function( creneau ) {
                               var cours = new Cours( { creneau_emploi_du_temps_id: creneau.id,
                                                        date_cours: new Date(creneau.heure_debut).toISOString(),
                                                        date_validation: null,
                                                        enseignant_id: $scope.current_user.uid,
                                                        contenu: ''} );
                               cours.devoirs = [];
                               cours.create = true;

                               return cours;
                           };
                           $scope.is_dirty = function( item ) {
                               item = typeof item !== 'undefined' ? item : null;
                               $scope.dirty = $scope.dirty || ( item === null || ( item !== null && item.contenu.length > 0 ) );
                           };

                           // Initialisations {{{
                           $scope.classes = classes;
                           $scope.matieres = _(matieres).sortBy( 'libelle_long' );

                           $scope.creneau = creneau;
                           $scope.mode_edition_creneau = $scope.creneau.en_creation;
                           $scope.creneau.regroupement_id = parseInt( $scope.creneau.regroupement_id );
                           $scope.creneau.mine = $scope.creneau.en_creation || _.chain( $scope.creneau.enseignants ).pluck( 'enseignant_id' ).include( $scope.current_user.uid ).value();
                           $scope.creneau.etranger = !$scope.current_user.profil_actif.admin && !$scope.creneau.en_creation && !$scope.creneau.mine;
                           $scope.creneau.previous_regroupement_id = $scope.creneau.regroupement_id;
                           $scope.creneau.vierge = _(creneau.vierge).isUndefined();
                           $scope.selected_regroupement = _($scope.creneau.regroupement_id).isUndefined() ? _( $scope.classes ).first() : _( $scope.classes ).findWhere( { id: parseInt( $scope.creneau.regroupement_id ) } );
                           $scope.selected_matiere = _($scope.creneau.matiere_id).isEmpty() ? _( $scope.matieres ).first() : _($scope.matieres).findWhere( { id: $scope.creneau.matiere_id } );
                           if ( $scope.creneau.en_creation ) {
                               $scope.creneau.tmp_heure_debut = $filter( 'correctTimeZoneToGMT' )( $scope.creneau.heure_debut );
                               $scope.creneau.tmp_heure_fin = $filter( 'correctTimeZoneToGMT' )( $scope.creneau.heure_fin );
                           } else {
                               $scope.creneau.tmp_heure_debut = angular.copy( $scope.creneau.heure_debut );
                               $scope.creneau.tmp_heure_fin = angular.copy( $scope.creneau.heure_fin );

                               _($scope.creneau.regroupements).each( function( regroupement ) {
                                   regroupement.regroupement_id = parseInt( regroupement.regroupement_id );
                               } );
                           }
                           $scope.creneau.tmp_heure_debut = moment( $scope.creneau.tmp_heure_debut );
                           $scope.creneau.tmp_heure_fin = moment( $scope.creneau.tmp_heure_fin );
                           $scope.creneau.n_week = moment($scope.creneau.tmp_heure_debut).week();

                           // Gestion des semaines actives
                           var what_month = function( n_week ) {
                               var now = moment();
                               var year = moment().year();
                               if ( n_week < 36 ) {
                                   if ( now.month() > 7 ) {
                                       year++;
                                   }
                               } else {
                                   if ( now.month() < 7 ) {
                                       year--;
                                   }
                               }
                               return moment( new Date( year ) ).isoWeek( n_week ).month();
                           };

                           var tmp_overlay_semainier = _.range(1, 52).map( function( s ) { return { semaine: s,
                                                                                                    mois: what_month( s ) }; } );

                           $scope.overlay_semainier = tmp_overlay_semainier;
                           $scope.overlay_semainier = _.chain($scope.overlay_semainier)
                               .groupBy( function( s ) { return s.mois; } )
                               .toArray()
                               .value();

                           var fixnum_to_bitfield = function( fixnum ) {
                               var string = fixnum.toString(2);
                               var padding = '';
                               _(52 - string.length).times( function() { padding += '0'; } );
                               string = padding + string;
                               return _(string.split('')
                                        .map( function( e ) { return parseInt( e ); } )
                                        .reverse())
                                   .rest();
                           };
                           var bitfield_to_fixnum = function( bitfield ) {
                               return parseInt( bitfield.reverse().join('') + '0', 2 );
                           };
                           $scope.sont_ce_les_vacances = function( i_semaine, zone ) {
                               return SEMAINES_VACANCES[ zone ].indexOf( i_semaine ) != -1;
                           };
                           var semaines_toutes_actives = function() {
                               var semainier = [];
                               _(52).times( function( i ) {
                                   if ( !$scope.sont_ce_les_vacances( i + 1, ZONE ) ) {
                                       semainier.push( 1 );
                                   } else {
                                       semainier.push( 0 );
                                   }
                               });

                               return semainier;
                           };

                           $scope.semaines_actives = { regroupement: [] };
                           $scope.templates_semainier = [
                               { label: 'Tout',
                                 apply: function() {
                                     $scope.semaines_actives.regroupement = semaines_toutes_actives();
                                 }
                               },
                               { label: 'Semaine A',
                                 apply: function() {
                                     var template = [];
                                     var semaines_depuis_les_vacances = 0;
                                     _(52).times( function( i ) {
                                         if ( $scope.sont_ce_les_vacances( i + 1, ZONE ) ) {
                                             semaines_depuis_les_vacances = 0;
                                         } else {
                                             semaines_depuis_les_vacances++;
                                         }
                                         template.push( ( semaines_depuis_les_vacances % 2 == 1 ) ? 1 : 0 );
                                     });
                                     $scope.semaines_actives.regroupement = template;
                                 }
                               },
                               { label: 'Semaine B',
                                 apply: function() {
                                     var template = [];
                                     var semaines_depuis_les_vacances = 0;
                                     _(52).times( function( i ) {
                                         if ( $scope.sont_ce_les_vacances( i + 1, ZONE ) ) {
                                             semaines_depuis_les_vacances = 0;
                                         } else {
                                             semaines_depuis_les_vacances++;
                                         }
                                         template.push( ( semaines_depuis_les_vacances % 2 == 0 ) ? 1 : 0 );
                                     });
                                     $scope.semaines_actives.regroupement = template;
                                 }
                               },
                               { label: 'Unique',
                                 apply: function() {
                                     var template = [];
                                     _(52).times( function( week ) {
                                         template.push( ( week + 1 == $scope.creneau.n_week ) ? 1 : 0 );
                                     });
                                     $scope.semaines_actives.regroupement = template;
                                 }
                               },
                               { label: 'Inverser',
                                 apply: function() {
                                     $scope.semaines_actives.regroupement = _($scope.semaines_actives.regroupement).map( function( w, i ) {
                                         return ( ( w == 0 ) && !$scope.sont_ce_les_vacances( i + 1, ZONE ) ) ? 1 : 0;
                                     } );
                                 }
                               },
                               { label: 'Réinitialiser',
                                 apply: function() {
                                     $scope.semaines_actives.regroupement = $scope.creneau.en_creation ? semaines_toutes_actives() : fixnum_to_bitfield( _(creneau.regroupements).findWhere( { regroupement_id: creneau.regroupement_id } ).semaines_de_presence );
                                 }
                               }
                           ];
                           _($scope.templates_semainier).findWhere( { label: 'Réinitialiser' } ).apply();

                           // helpers
                           $scope.fermer = function () {
                               $uibModalInstance.close( $scope );
                           };

                           $scope.effacer_creneau = function() {
                               var do_it = function () {
                                   CreneauxEmploiDuTemps.delete( {
                                       id: $scope.creneau.id,
                                       date_creneau: $scope.creneau.heure_debut
                                   } )
                                       .$promise.then( function () {
                                           $scope.actions_done.push( POPUP_ACTIONS.CRENEAU_DELETED );
                                           $scope.fermer();
                                       } );
                               };
                               if ( $scope.dirty ) {
                                   swal( { title: 'Ceci supprimera le créneau à compter du ' + $filter( 'amDateFormat' )( creneau.heure_debut, 'dddd D MMMM YYYY' ),
                                           text: 'Le créneau avec ses séquences pédagogiques et devoirs associés restera visible pour les dates antérieures.',
                                           type: 'warning',
                                           showCancelButton: true,
                                           confirmButtonColor: '#ff6b55',
                                           confirmButtonText: 'Confirmer',
                                           cancelButtonText: 'Annuler'
                                         },
                                         do_it );
                               } else {
                                   do_it();
                               }
                           };

                           $scope.annuler = function () {
                               var do_it = function () {
                                   if ( $scope.creneau.en_creation ) {
                                       $scope.effacer_creneau();
                                   } else {
                                       $scope.dirty = false;
                                       if ( $scope.actions_done.length == 0 ) {
                                           $scope.actions_done.push( POPUP_ACTIONS.CANCELLED );
                                       }
                                       $scope.fermer();
                                   }
                               };
                               if ( $scope.dirty ) {
                                   swal( { title: 'Êtes-vous sur ?',
                                           text: 'Les modifications que vous avez faites dans cette fenêtre seront perdues.',
                                           type: 'warning',
                                           showCancelButton: true,
                                           confirmButtonColor: '#ff6b55',
                                           confirmButtonText: 'Confirmer',
                                           cancelButtonText: 'Annuler'
                                         },
                                         do_it);
                               } else {
                                   do_it();
                               }
                           };

                           $scope.valider = function () {
                               // réinitialisation des erreurs
                               $scope.erreurs = [];
                               var promesses = [];

                               if ( $scope.mode_edition_creneau ) {
                                   $scope.creneau.matiere_id = $scope.selected_matiere.id;
                                   $scope.creneau.regroupement_id = $scope.selected_regroupement.id;
                                   if ( $scope.creneau.tmp_heure_debut > $scope.creneau.tmp_heure_fin ) {
                                       var tmp = $scope.creneau.tmp_heure_debut;
                                       $scope.creneau.tmp_heure_debut = $scope.creneau.tmp_heure_fin;
                                       $scope.creneau.tmp_heure_fin = tmp;
                                   }
                                   $scope.creneau.heure_debut = $filter('correctTimeZone')( $scope.creneau.tmp_heure_debut );
                                   $scope.creneau.heure_fin = $filter('correctTimeZone')( $scope.creneau.tmp_heure_fin );
                                   $scope.creneau.semaines_de_presence_regroupement = bitfield_to_fixnum( $scope.semaines_actives.regroupement );

                                   $scope.creneau.$update();

                                   $scope.actions_done.push( POPUP_ACTIONS.CRENEAU_MODIFIED );
                               } else {
                                   // Gestion des Cours et Devoirs
                                   var valider_devoirs = function( devoirs, cours ) {
                                       _( devoirs ).each( function ( devoir ) {
                                           if ( _( devoir ).has( 'contenu' ) && ( devoir.contenu.length > 0 ) ) {
                                               // FIXME: on $save() ou $update() tous les devoirs qu'ils aient été modifiés ou non
                                               var prom = $q.defer();
                                               if ( devoir.create ) {
                                                   devoir.regroupement_id = $scope.selected_regroupement.id;
                                                   if ( ! _(cours).isNull() ) {
                                                       devoir.cours_id = cours.id;
                                                   }
                                                   devoir.$save().then( function success( result ) {
                                                       devoir.id = result.id;
                                                       prom.resolve( result );
                                                       $scope.actions_done.push( POPUP_ACTIONS.DEVOIR_CREATED );
                                                   }, function ( response ) {
                                                       $scope.erreurs.unshift( {
                                                           status: response.status,
                                                           message: response.data.error
                                                       } );
                                                       prom.reject( response );
                                                   } );
                                               } else {
                                                   devoir.$update().then( function success( result ) {
                                                       devoir.id = result.id;
                                                       prom.resolve( result );
                                                       $scope.actions_done.push( POPUP_ACTIONS.DEVOIR_MODIFIED );
                                                   }, function ( response ) {
                                                       $scope.erreurs.unshift( {
                                                           status: response.status,
                                                           message: response.data.error
                                                       } );
                                                       prom.reject( response );
                                                   } );
                                               }

                                               promesses.push( prom.promise );
                                           }
                                       } );
                                   };

                                   // Séquence Pédogogique du créneau
                                   if ( ( _($scope.cours).has('contenu') && $scope.cours.contenu.length > 0 ) || ( $scope.cours.devoirs.length > 0 ) ) {
                                       var promesse = $q.when( true );
                                       var cours_devoirs = _($scope.cours.devoirs).map( function( devoir ) {
                                           return new Devoirs( devoir );
                                       });

                                       if ( $scope.cours.create ) {
                                           $scope.cours.regroupement_id = $scope.selected_regroupement.id;
                                           $scope.cours.creneau_emploi_du_temps_id = $scope.creneau.id;
                                           promesse = $scope.cours.$save();
                                           $scope.actions_done.push( POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_CREATED );
                                       } else {
                                           promesse = $scope.cours.$update();
                                           $scope.actions_done.push( POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_MODIFIED );
                                       }

                                       // Devoirs liés au cours
                                       if ( cours_devoirs.length > 0 ) {
                                           promesse.then( function ( cours_from_DB ) {
                                               valider_devoirs( cours_devoirs, cours_from_DB );
                                           } );
                                       }
                                   }

                                   // Devoirs dûs ce créneau
                                   valider_devoirs( $scope.devoirs, null );
                               }

                               $q.all( promesses ).then( $scope.fermer );
                           };





                           // Gestion des Cours et Devoirs ///////////////////////////////////////////////////////////////////////////
                           if ( ! $scope.creneau.en_creation ) {
                               // fonctions UI pour le temps estimé
                               $scope.estimation_over = function ( d, value ) {
                                   d.overValue = value;
                                   d.minutes = 5 * value;
                               };
                               $scope.estimation_leave = function ( d ) {
                                   $scope.estimation_over( d, d.temps_estime );
                               };

                               $scope.devoirs = devoirs.map( function( devoir ) {
                                   return Devoirs.get( { id: devoir.id } );
                               } );

                               $scope.types_de_devoir = API.query_types_de_devoir();

                               var init_cours_existant = function( cours ) {
                                   $scope.cours = Cours.get( { id: cours.id } );
                                   $scope.cours.$promise.then( function( cours ) {
                                       $scope.cours.editable = _($scope.cours.date_validation).isNull() && $scope.cours.enseignant_id === $scope.current_user.uid;
                                       if ( !$scope.cours.editable ) {
                                           $scope.cours.contenu = $sce.trustAsHtml( $scope.cours.contenu );
                                       }

                                       cours.devoirs = _(cours.devoirs).map( function( devoir ) {
                                           return Devoirs.get( { id: devoir.id } );
                                       } );

                                       _(cours.devoirs).each( function( devoir ) {
                                           devoir.$promise.then( function( d ) {
                                               $scope.estimation_leave( d );
                                               d.tooltip = d.contenu;
                                               if ( d.temps_estime > 0 ) {
                                                   d.tooltip = '<span><i class="picto temps"></i>' + d.temps_estime * 5 + ' minutes</span><hr>' + d.tooltip;
                                               }
                                               if ( $scope.creneau.etranger ) {
                                                   d.contenu = $sce.trustAsHtml( d.contenu );
                                               }
                                           } );
                                       } );

                                       $q.all( $scope.devoirs ).then( function() {
                                           $scope.cours.devoirs = _($scope.cours.devoirs).filter( function( devoir ) {
                                               return _.chain($scope.devoirs).findWhere({ id: devoir.id }).isUndefined().value();
                                           } );
                                       } );

                                       $scope.cours.$promise.then( function() {
                                           _($scope.cours.ressources).each( function( ressource ) {
                                               ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
                                           } );
                                       } );
                                       _($scope.cours.devoirs).each( function( devoir ) {
                                           devoir.$promise.then( function() {
                                               _(devoir.ressources).each( function( ressource ) {
                                                   ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
                                               } );
                                           } );
                                       } );

                                   } );
                                   $scope.cours.create = false;
                               };

                               if ( _(cours).isNull() ) {
                                   if ( !$scope.creneau.etranger ) {
                                       $scope.cours = create_cours( creneau );
                                       $scope.cours.editable = true;
                                   }
                               } else {
                                   init_cours_existant( cours );
                               }

                               _( $scope.devoirs )
                                   .each( function ( devoir ) {
                                       devoir.$promise.then( function() {
                                           $scope.estimation_leave( devoir );
                                           _(devoir.ressources).each( function( ressource ) {
                                               ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
                                           } );
                                           if ( $scope.creneau.etranger ) {
                                               devoir.contenu = $sce.trustAsHtml( devoir.contenu );
                                           }
                                       } );
                                   } );

                               // Fonction UI pour fixer l'id du créneau en fct du choix dans la sbox des créneaux possibles.
                               $scope.set_creneau_date_due = function ( devoir ) {
                                   // on prend le premier créneau qui correspond à cette date.
                                   var creneau_choisi = _( $scope.creneaux_devoirs_possibles ).findWhere( {
                                       date_due: devoir.date_due
                                   } );
                                   devoir.creneau_emploi_du_temps_id = creneau_choisi.creneau_emploi_du_temps_id;
                                   $scope.is_dirty();
                               };

                               var liste_créneaux_similaires = function( creneau, n_semaines_before, n_semaines_after ) {
                                   return API.get_creneaux_emploi_du_temps_similaires({ id: creneau.id,
                                                                                        debut: moment( creneau.heure_debut.toISOString() ).subtract( n_semaines_before, 'weeks' ).toDate(),
                                                                                        fin: moment( creneau.heure_debut.toISOString() ).add( n_semaines_after, 'weeks' ).toDate() } );
                               };

                               liste_créneaux_similaires( $scope.creneau, 2, 8 )
                                   .then( function( response ) {
                                       $scope.creneaux_devoirs_possibles_duplication = [];
                                       $scope.creneaux_similaires = _.chain(response.data)
                                           .reject( function( creneau ) { return creneau.regroupement_id === 'undefined'; } )
                                           .reject( function( creneau ) { return creneau.has_cours; } )
                                           .map( function ( creneau ) {
                                               creneau.classe = _( $scope.classes ).findWhere( { id: parseInt( creneau.regroupement_id ) } );
                                               creneau.heure_debut = new Date( creneau.heure_debut );
                                               creneau.heure_fin = new Date( creneau.heure_fin );

                                               return creneau;
                                           } )
                                           .value();
                                       $scope.creneaux_similaires.selected = [];
                                   } );

                               liste_créneaux_similaires( $scope.creneau, 0, 8 )
                                   .then( function( response ) {
                                       $scope.creneaux_devoirs_possibles = _.chain(response.data)
                                           .select( function( creneau ) { return creneau.regroupement_id == $scope.creneau.regroupement_id; } )
                                           .map( function ( creneau ) {
                                               creneau.classe = _( $scope.classes ).findWhere( { id: parseInt( creneau.regroupement_id ) } );
                                               creneau.date_due = $filter( 'date' )( creneau.start, 'y-MM-dd' );
                                               creneau.semaine = moment( creneau.start).from( moment( $scope.creneau.heure_debut ) );
                                               creneau.heure_debut = new Date( creneau.heure_debut );
                                               creneau.heure_fin = new Date( creneau.heure_fin );

                                               return creneau;
                                           } )
                                           .sortBy( function ( creneau ) { // Trie par dates croissantes
                                               return creneau.start;
                                           } )
                                           .value();
                                       if ( $scope.creneaux_devoirs_possibles.length > 1 ) {
                                           $scope.creneaux_devoirs_possibles = _($scope.creneaux_devoirs_possibles)
                                               .select( function ( creneau ) {
                                                   return creneau.heure_debut.toISOString() != $scope.creneau.heure_debut.toISOString();
                                               } );
                                       }
                                   } );

                               // {{{ Gestion des documents attachés
                               $scope.cartable = {};
                               $scope.cartable.expandedNodes = [];
                               $scope.treeOptions = {
                                   dirSelectable: false
                               };

                               var dead_Documents = function() {
                                   $scope.erreurs.push( { message: "Application Documents non disponible" } );
                                   $scope.faulty_docs_app = true;
                               };

                               if ( LOCALHOST ) {
                                   $scope.erreurs.push( { message: "Instance sur localhost" } );
                                   $scope.faulty_docs_app = true;
                               } else {
                                   Documents.list_files()
                                       .success( function ( response ) {
                                           if ( _(response.error).isEmpty() && _(response).has( 'files' ) ) {
                                               $scope.cartable = response;
                                               $scope.cartable.files = _( response.files ).reject( function( file ) {
                                                   return _(file).has( 'phash' );
                                               } ); //.rest();
                                               $scope.cartable.expandedNodes = [];
                                           } else {
                                               dead_Documents();
                                           }
                                       } )
                                       .error( dead_Documents );
                               }

                               $scope.consume_Documents_response_callback = function( item ) {
                                   return function( response ) {
                                       $scope.erreurs = [];
                                       if ( !_(response.error).isEmpty() ) {
                                           $scope.erreurs.push( { message: response.error } );
                                       } else {
                                           item.ressources.push( {
                                               name: _( response.added ).first().name,
                                               hash: _( response.added ).first().hash,
                                               url: $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + _( response.added ).first().hash )
                                           } );
                                           $scope.is_dirty();
                                       }
                                   };
                               };

                               $scope.upload_and_add_ressource = function ( item, fichiers ) {
                                   if ( item.ressources === undefined ) {
                                       item.ressources = [];
                                   }
                                   var responses = Documents.upload_dans_cahier_de_textes( $scope.selected_regroupement, fichiers );
                                   for ( var i = 0; i < responses.length; i++ ) {
                                       responses[ i ]
                                           .success( $scope.consume_Documents_response_callback( item ) )
                                           .error( function ( response ) {
                                               console.debug( response.error );
                                           } );
                                   }
                               };

                               $scope.remove_ressource = function ( item, hash ) {
                                   item.ressources = _( item.ressources ).reject( function ( ressource ) {
                                       return ressource.hash == hash;
                                   } );
                                   $scope.is_dirty();
                               };
                               // }}}

                               // fonctions d'événements GUI {{{
                               $scope.ajout_devoir = function( where, creneau_cible ) {
                                   if ( _(creneau_cible).isNull() ) {
                                       creneau_cible = $scope.creneau;
                                   } else if ( creneau_cible == 'next' ) {
                                       if ( $scope.creneaux_devoirs_possibles.length > 1 ) {
                                           creneau_cible = _.chain($scope.creneaux_devoirs_possibles)
                                               .select( function( creneau ) {
                                                   return creneau.heure_debut > $scope.creneau.heure_debut;
                                               } )
                                               .head()
                                               .value();
                                       } else {
                                           creneau_cible = _($scope.creneaux_devoirs_possibles).first();
                                       }
                                   }
                                   var devoir = new Devoirs( {
                                       cours_id: $scope.cours.id,
                                       date_due: $filter( 'date' )( creneau_cible.heure_debut, 'yyyy-MM-dd' ),
                                       type_devoir_id: _($scope.types_de_devoir).last().id,
                                       creneau_emploi_du_temps_id: creneau_cible.id
                                   } );
                                   devoir.create = true;
                                   where.unshift( devoir );
                               };

                               $scope.ok_go_for_duplication = false;
                               $scope.are_we_go_for_duplication = function() {
                                   $scope.ok_go_for_duplication = !_($scope.creneaux_similaires.selected).isEmpty()
                                       && _($scope.cours.devoirs).reduce( function( is_it, devoir ) { return is_it && _(devoir).has('creneau_cible'); }, true );
                               };

                               $scope.creneau_cible_duplication_SP_updated = function() {
                                   // Calcul des créneaux cibles pour les devoirs
                                   liste_créneaux_similaires( $scope.creneaux_similaires.selected, 0, 4 )
                                       .then( function( response ) {
                                           $scope.creneaux_devoirs_possibles_duplication = _.chain(response.data)
                                               .select( function( creneau ) { return creneau.regroupement_id == $scope.creneaux_similaires.selected.regroupement_id; } )
                                               .map( function ( creneau ) {
                                                   creneau.classe = _( $scope.classes ).findWhere( { id: parseInt( creneau.regroupement_id ) } );
                                                   creneau.date_due = $filter( 'date' )( creneau.start, 'y-MM-dd' );
                                                   creneau.semaine = moment( creneau.start).from( moment( $scope.creneau.heure_debut ), true ) + ' plus tard';
                                                   creneau.heure_debut = new Date( creneau.heure_debut );
                                                   creneau.heure_fin = new Date( creneau.heure_fin );

                                                   return creneau;
                                               } )
                                               .value();
                                       } );
                                   $scope.are_we_go_for_duplication();
                               };

                               $scope.dupliquer = function () {
                                   var devoirs = angular.copy( $scope.cours.devoirs );
                                   $scope.cours.$copie( {
                                       regroupement_id: $scope.creneaux_similaires.selected.regroupement_id,
                                       creneau_emploi_du_temps_id: $scope.creneaux_similaires.selected.creneau_emploi_du_temps_id,
                                       date: $scope.creneaux_similaires.selected.start
                                   } ).then( function() {
                                       $scope.actions_done.push( POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_DUPLICATED );
                                       toastr.success( '', 'Séquence pédagogique copiée.');

                                       _(devoirs).each( function( devoir ) {
                                           devoir.$copie( {
                                               cours_id: $scope.cours.copie_id,
                                               creneau_emploi_du_temps_id: devoir.creneau_cible.id,
                                               date_due: devoir.creneau_cible.date_due
                                           } )
                                               .then( function() {
                                                   $scope.actions_done.push( POPUP_ACTIONS.DEVOIR_DUPLICATED );
                                                   toastr.success( '', 'Devoir copié.');
                                                   devoir.creneau_cible = [];
                                               } );
                                       } );
                                       $scope.creneaux_similaires = _($scope.creneaux_similaires).reject( function( creneau ) {
                                           return creneau.id + creneau.start == $scope.creneaux_similaires.selected.id + $scope.creneaux_similaires.selected.start;
                                       } );
                                       $scope.creneaux_similaires.selected = [];
                                       init_cours_existant( $scope.cours );

                                       swal( { title: 'Créneau copié !',
                                               type: 'success',
                                               timer: 2000,
                                               showCancelButton: false,
                                               confirmButtonColor: '#ff6b55',
                                               confirmButtonText: 'Fermer'
                                             } );
                                   } );
                               };

                               $scope.effacer_cours = function () {
                                   $scope.cours.$delete()
                                       .then( function () {
                                           $scope.actions_done.push( POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_DELETED );
                                           init_cours_existant( $scope.cours );
                                       } );
                               };

                               $scope.effacer_devoir = function ( devoir ) {
                                   if ( _(devoir).has('id') ) {
                                       devoir.$delete().then( function() {
                                           $scope.actions_done.push( POPUP_ACTIONS.DEVOIR_DELETED );
                                       } );
                                   } else {
                                       devoir.deleted = true;
                                   }
                               };

                               $scope.switch_to_duplication_mode = function() {
                                   $scope.mode_duplication = true;
                               };

                               $scope.switch_to_modification_mode = function() {
                                   $scope.mode_edition_creneau = false;
                                   $scope.mode_duplication = false;
                               };

                               $scope.switch_to_creneau_edition = function() {
                                   $scope.dirty = true;
                                   $scope.erreurs = [];
                                   $scope.mode_edition_creneau = true;
                               };
                           }	// /fin gestion des Cours et Devoirs
                           // }}}

                           angular.element('#ui-view-content').after( $scope.current_user.marqueur_xiti );
                       } );
                   } ] );
