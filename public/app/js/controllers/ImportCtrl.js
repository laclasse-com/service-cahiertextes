'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('ImportCtrl',
                [ '$scope', '$http', '$locale', '$sce', '$filter', 'fileUpload', 'moment', 'toastr', '$q',
                  'APP_PATH', 'SEMAINES_VACANCES', 'ZONE', 'VERSION',
                  'Annuaire', 'Utils', 'Etablissements', 'CreneauxEmploiDuTemps', 'API', 'Matchable',
                  'current_user',
                  function ( $scope, $http, $locale, $sce, $filter, fileUpload, moment, toastr, $q,
                             APP_PATH, SEMAINES_VACANCES, ZONE, VERSION,
                             Annuaire, Utils, Etablissements, CreneauxEmploiDuTemps, API, Matchable,
                             current_user ) {
                      $scope.scope = $scope;
                      $scope.jours_de_la_semaine = $locale.DATETIME_FORMATS.DAY;
                      $scope.annee = $locale.DATETIME_FORMATS.MONTH;
                      $scope.fichier = null;
                      $scope.display_all = false;
                      $scope.step = 0;
                      $scope.report = {};

                      $scope.ui = { show_detailed_creneaux: false,
                                    display_ready: true,
                                    display_problems: true,
                                    sortCreneauxBy: [ 'Jour' ],
                                    sort_creneaux_by: function( criteria ) {
                                        $scope.ui.sortCreneauxBy = $scope.ui.sortCreneauxBy[0] === criteria[0] ?  _(criteria).map( function( sub_criteria ) { return '-' + sub_criteria; } ) : criteria;
                                    } };

                      $scope.beautify_semainier = function( semainier ) {
                          var bsemainier = Utils.padEnd( semainier.toString( 2 ), 53, '0' );

                          return '<div class="semainier-tooltip gris1">' +
                              _.chain(Utils.overlay_semainier())
                              .sortBy( function( month ) { return month.index; } )
                              .map( function( month ) {
                                  var month_html = '<div class="month blanc"><h5 class="month-name gris4">' + month.label + '</h5>';

                                  month_html += _(month.semaines).map( function( week ) {
                                      var week_html = '<span class="week';
                                      if ( Utils.sont_ce_les_vacances( week.semaine, ZONE ) ) { week_html += ' vacances gris2'; }
                                      if ( bsemainier[ week.semaine ] === '1' ) { week_html += ' active orange-moins'; }
                                      week_html += '">' + week.semaine + '</span>';

                                      return week_html;
                                  } ).join('');

                                  month_html += '</div>';

                                  return month_html;
                              } )
                              .value()
                              .join('') +
                              '<div class="clearfix"></div></div>';
                      };

                      $scope.filter_creneau = function( options, criteria ) {
                          return function( creneau ) {
                              if ( !options.display_problems && !creneau.ready ) { return false; }
                              if ( !options.display_ready && creneau.ready ) { return false; }

                              creneau.is_displayed = true;
                              if ( _(criteria.classes).isEmpty() && _(criteria.groupes).isEmpty() ) {
                                  creneau.is_displayed = creneau.is_displayed &&
                                      !_(creneau).has( 'Classe' ) &&
                                      !_(creneau).has( 'Groupe' );
                              } else if ( _(criteria.classes).isEmpty() && !_(criteria.groupes).isEmpty() ) {
                                  creneau.is_displayed = creneau.is_displayed &&
                                      !_(creneau).has( 'Classe' ) &&
                                      _(creneau).has( 'Groupe' ) &&
                                      _.chain(criteria.groupes).pluck( 'Ident' ).includes( creneau.Groupe.Ident ).value();
                              } else if ( !_(criteria.classes).isEmpty() && _(criteria.groupes).isEmpty() ) {
                                  creneau.is_displayed = creneau.is_displayed &&
                                      _(creneau).has( 'Classe' ) &&
                                      !_(creneau).has( 'Groupe' ) &&
                                      _.chain(criteria.classes).pluck( 'Ident' ).includes( creneau.Classe.Ident ).value();
                              } else {
                                  creneau.is_displayed = creneau.is_displayed &&
                                      ( ( _(creneau).has( 'Groupe' ) && _.chain(criteria.groupes).pluck( 'Ident' ).includes( creneau.Groupe.Ident ).value() ) ||
                                        ( _(creneau).has( 'Classe' ) && _.chain(criteria.classes).pluck( 'Ident' ).includes( creneau.Classe.Ident ).value() ) );
                              }
                              if ( !creneau.is_displayed ) {
                                  return false;
                              }

                              if ( _(criteria.matieres).isEmpty() ) {
                                  creneau.is_displayed = creneau.is_displayed && !_(creneau).has( 'Matiere' );
                              } else {
                                  creneau.is_displayed = creneau.is_displayed &&
                                      _(creneau).has( 'Matiere' ) &&
                                      _.chain(criteria.matieres).pluck( 'Ident' ).includes( creneau.Matiere.Ident ).value();
                              }
                              if ( !creneau.is_displayed ) {
                                  return false;
                              }

                              return creneau.is_displayed;
                          };
                      };

                      // ********** counters
                      var update_counters = function() {
                          var filtered_creneaux = $filter('filter')( $scope.creneaux, $scope.filter_creneau( $scope.ui, $scope.selected ) );
                          $scope.counters = {};

                          $scope.counters.creneaux = $scope.creneaux.length;
                          $scope.counters.creneaux_broken = _($scope.pronote.Cours[0].Cours).select( function( cours ) { return !_(cours).has( 'Matiere' ) || !_(cours).has( 'Professeur' ) || ( !_(cours).has( 'Classe' ) && !_(cours).has( 'Groupe' ) ); } ).length;
                          $scope.counters.creneaux_not_ready = _($scope.creneaux).where({ ready: false }).length;
                          $scope.counters.creneaux_ready = $scope.counters.creneaux - $scope.counters.creneaux_not_ready;

                          $scope.counters.filtered_creneaux = filtered_creneaux.length;
                          $scope.counters.filtered_creneaux_not_ready = _(filtered_creneaux).where({ ready: false }).length;
                          $scope.counters.filtered_creneaux_ready = $scope.counters.filtered_creneaux - $scope.counters.filtered_creneaux_not_ready;

                          $scope.counters.percent_creneaux_ready = $scope.counters.filtered_creneaux_ready / $scope.counters.filtered_creneaux;
                      };
                      // ********** /counters

                      // ********** readiness
                      var update_creneaux_readiness = function() {
                          _($scope.creneaux).each( function( creneau ) {
                              creneau.readiness = { matiere: !_($scope.pronote.matieres[ creneau.Matiere.Ident ].laclasse).isUndefined(),
                                                    salle: !_(creneau.Salle).isUndefined(),
                                                    classe: _(creneau).has('Classe') && !_($scope.pronote.classes[ creneau.Classe.Ident ].laclasse).isUndefined(),
                                                    groupe_eleve: _(creneau).has('Groupe') && !_($scope.pronote.groupes_eleves[ creneau.Groupe.Ident ].laclasse).isUndefined() };

                              creneau.ready = creneau.readiness.matiere && ( creneau.readiness.classe || creneau.readiness.groupe_eleve );
                          } );

                          update_counters();
                      };
                      // ********** /readiness

                      var hash_me = function( item ) {
                          var get_type = function( item ) {
                              if ( _(item).has('PartieDeClass') ) { return 'regroupement'; }
                              else if ( _(item).has('Code') ) { return 'matiere'; }
                              else { return 'unknown'; }
                          };

                          return window.btoa( unescape( encodeURIComponent( get_type( item ) + item.displayed_label ) ) );
                      };

                      // ACTIONS
                      var load_data = function( fichier ) {
                          $scope.pronote = false;
                          $scope.matcheable_data = [];
                          var handle_error = function( response ) {
                              return $q.reject( response );
                          };

                          toastr.info('Déchiffrage du fichier');
                          return fileUpload.uploadFileToUrl( fichier, APP_PATH + '/api/import/pronote/decrypt' )
                              .then(
                                  function success( response ) {
                                      // 1. Récupérer le fichier Pronote décrypté
                                      $scope.pronote = response.data;
                                      $scope.pronote.GrilleHoraire[0].DureePlace = parseInt( $scope.pronote.GrilleHoraire[0].DureePlace );

                                      toastr.info('récupération des données de l\'établissement');
                                      // 2. Récupérer toutes les infos de l'établissement et toutes les matières
                                      return Etablissements.get( { uai: $scope.pronote.UAI } ).$promise;
                                  },
                                  handle_error
                              )
                              .then(
                                  function success( response ) {
                                      $scope.etablissement_summary = response;
                                      _($scope.etablissement_summary.imports).each( function( i ) { i.date_import = new Date( i.date_import ); } );

                                      return Annuaire.get_structure( $scope.pronote.UAI );
                                  },
                                  handle_error
                              )
                              .then(
                                  function success( response ) {
                                      $scope.etablissement = { classes: _(response.data.groups).where( { type: 'CLS' } ),
                                                               groupes_eleves: _(response.data.groups).select( { type: 'GRP' } ) };

                                      _($scope.etablissement.groupes_eleves).each( function( regroupement ) {
                                          regroupement.libelle_aaf = regroupement.name.toUpperCase();
                                          regroupement.displayed_label = regroupement.name;
                                      } );
                                      _($scope.etablissement.classes).each( function( regroupement ) {
                                          regroupement.libelle_aaf = regroupement.name.toUpperCase();
                                          regroupement.displayed_label = regroupement.name;
                                      } );

                                      toastr.info('traitement des données des regroupements');
                                      // 3.3 Classes et Groupes
                                      return API.query_statistiques_regroupements( { uai: current_user.profil_actif.structure_id } ).$promise;
                                  },
                                  handle_error
                              )
                              .then(
                                  function success( response ) {
                                      _($scope.pronote.Classes[0].Classe)
                                          .each( function( regroupement ) {
                                              regroupement.displayed_label = regroupement.Nom;
                                              regroupement.laclasse = _($scope.etablissement.classes).findWhere( { libelle_aaf: regroupement.Nom.toUpperCase() } );

                                              if ( _(regroupement.laclasse).isUndefined() ) {
                                                  var matched = _($scope.etablissement_summary.matchables).findWhere({ hash_item: hash_me( regroupement ) });
                                                  if ( !_(matched).isUndefined() ) {
                                                      regroupement.laclasse = _($scope.etablissement.classes).findWhere({ id: matched.id_annuaire });
                                                  }
                                              }

                                              regroupement.edit = _(regroupement.laclasse).isUndefined();
                                              var creneaux_laclasse = _(regroupement.laclasse).isUndefined() ? undefined : _(response).findWhere({ regroupement_id: "" + regroupement.laclasse.id });
                                              regroupement.existing_creneaux = _(creneaux_laclasse).isUndefined() ? 0 : creneaux_laclasse.creneaux_emploi_du_temps.vides.length + creneaux_laclasse.creneaux_emploi_du_temps.pleins.length;

                                              if ( !regroupement.edit ) {
                                                  regroupement.laclasse.displayed_label = regroupement.laclasse.libelle_aaf;
                                              }
                                          } );

                                      _($scope.pronote.Groupes[0].Groupe)
                                          .each( function( regroupement ) {
                                              regroupement.displayed_label = regroupement.Nom;
                                              regroupement.laclasse = _($scope.etablissement.groupes_eleves).findWhere( { libelle_aaf: regroupement.Nom.toUpperCase() } );

                                              if ( _(regroupement.laclasse).isUndefined() ) {
                                                  var matched = _($scope.etablissement_summary.matchables).findWhere({ hash_item: hash_me( regroupement ) });
                                                  if ( !_(matched).isUndefined() ) {
                                                      regroupement.laclasse = _($scope.etablissement.groupes_eleves).findWhere({ id: matched.id_annuaire });
                                                  }
                                              }

                                              regroupement.edit = _(regroupement.laclasse).isUndefined();
                                              var creneaux_laclasse = _(regroupement.laclasse).isUndefined() ? undefined : _(response).findWhere({ regroupement_id: "" + regroupement.laclasse.id });
                                              regroupement.existing_creneaux = _(creneaux_laclasse).isUndefined() ? 0 : creneaux_laclasse.creneaux_emploi_du_temps.vides.length + creneaux_laclasse.creneaux_emploi_du_temps.pleins.length;

                                              if ( !regroupement.edit ) {
                                                  regroupement.laclasse.displayed_label = regroupement.laclasse.libelle_aaf;
                                              }
                                          } );

                                      toastr.info('traitement des données des cours');
                                      // 4. treating Cours
                                      $scope.creneaux = _.chain($scope.pronote.Cours[0].Cours)
                                          .map( function( cours ) {
                                              return _.chain(cours.Matiere).map( function( matiere ) {
                                                  var compute_cours = function( type_regroupement ) {
                                                      return function( regroupement ) {
                                                          var this_cours = angular.copy( cours );
                                                          this_cours.is_displayed = true;
                                                          this_cours.Matiere = matiere;

                                                          if ( type_regroupement === 'Classe' ) {
                                                              this_cours.Classe = regroupement;
                                                              this_cours.Classe.Semaines = Utils.fix_semainier_pronote( this_cours.Classe.Semaines, $scope.pronote.AnneeScolaire[0].DateDebut );
                                                          } else {
                                                              this_cours.Groupe = regroupement;
                                                              this_cours.Groupe.Semaines = Utils.fix_semainier_pronote( this_cours.Groupe.Semaines,$scope.pronote.AnneeScolaire[0].DateDebut );
                                                          }

                                                          if ( _(cours).has('Salle') ) {
                                                              return _(cours.Salle).map( function( salle ) {
                                                                  this_cours.Salle = salle;
                                                                  this_cours.Salle.Semaines = Utils.fix_semainier_pronote( this_cours.Salle.Semaines, $scope.pronote.AnneeScolaire[0].DateDebut );

                                                                  return this_cours;
                                                              } );
                                                          } else {
                                                              return this_cours;
                                                          }
                                                      };
                                                  };

                                                  return [ _(cours.Classe).map( compute_cours( 'Classe' ) ),
                                                           _(cours.Groupe).map( compute_cours( 'Groupe' ) ) ];
                                              } )
                                                  .flatten()
                                                  .uniq()
                                                  .value();
                                          } )
                                          .flatten()
                                          .value();

                                      $scope.pronote.classes = Utils.groupByKey( $scope.pronote.Classes[0].Classe, 'Ident' );
                                      $scope.pronote.salles = Utils.groupByKey( $scope.pronote.Salles[0].Salle, 'Ident' );
                                      $scope.pronote.plages_horaires = Utils.groupByKey( $scope.pronote.GrilleHoraire[0].PlacesParJour[0].Place, 'Numero' );
                                      $scope.pronote.groupes_eleves = Utils.groupByKey( $scope.pronote.Groupes[0].Groupe, 'Ident' );

                                      $scope.matcheable_data.push( { title: 'Classes',
                                                                     pronote: $scope.pronote.classes,
                                                                     annuaire: $scope.etablissement.classes } );
                                      $scope.matcheable_data.push( { title: 'Groupes d\'élèves',
                                                                     pronote: $scope.pronote.groupes_eleves,
                                                                     annuaire: $scope.etablissement.groupes_eleves } );

                                      toastr.info('Récupération des matieres');
                                      // 3.1 Matières
                                      return Annuaire.query_subjects();
                                  },
                                  handle_error
                              )
                              .then(
                                  function success( response ) {
                                      $scope.matieres = _(response.data).map( function( matiere ) {
                                          matiere.libelle_long = matiere.name.toUpperCase();
                                          matiere.displayed_label = matiere.name;

                                          return matiere;
                                      } );

                                      // 3. Matcher les 2
                                      _($scope.pronote.Matieres[0].Matiere)
                                          .each( function( matiere ) {
                                              matiere.displayed_label = matiere.Libelle;
                                              matiere.laclasse = _($scope.matieres).findWhere( { libelle_long: matiere.Libelle.toUpperCase() } );

                                              if ( _(matiere.laclasse).isUndefined() ) {

                                                  if ( _(matiere.laclasse).isUndefined() ) {
                                                      var matched = _($scope.etablissement_summary.matchables).findWhere({ hash_item: hash_me( matiere ) });
                                                      if ( !_(matched).isUndefined() ) {
                                                          matiere.laclasse = _($scope.matieres).findWhere({ id: matched.id_annuaire });
                                                      }
                                                  }
                                              }

                                              matiere.edit = _(matiere.laclasse).isUndefined();
                                              if ( !matiere.edit ) {
                                                  matiere.laclasse.displayed_label = matiere.laclasse.libelle_long;
                                              }
                                          } );

                                      $scope.pronote.matieres = Utils.groupByKey( $scope.pronote.Matieres[0].Matiere, 'Ident' );
                                      $scope.matcheable_data.push( { title: 'Matières',
                                                                     pronote: $scope.pronote.matieres,
                                                                     annuaire: $scope.matieres } );

                                      _($scope.matcheable_data).each( function( dataset ) {
                                          dataset.total = function() { return _(dataset.pronote).size(); };
                                          dataset.unmatched = function() { return _(dataset.pronote).where( { laclasse: undefined } ).length; };
                                          dataset.percent_valid = function() { return ( dataset.total() - dataset.unmatched() ) / dataset.total(); };
                                      } );

                                      $scope.selected = { matieres: $scope.pronote.Matieres[0].Matiere,
                                                          classes: _($scope.pronote.Classes[0].Classe).where({ existing_creneaux: 0 }),
                                                          groupes: _($scope.pronote.Groupes[0].Groupe).where({ existing_creneaux: 0 }) };

                                      update_creneaux_readiness();

                                      $scope.$watchCollection( 'selected', function() { update_counters(); } );
                                  },
                                  handle_error
                              )
                              .then(
                                  function success( response ) {
                                      $scope.step++;
                                      return $q.resolve( true );
                                  },
                                  handle_error
                              );
                      };

                      var import_data = function() {
                          var started_at = moment();
                          var bulk_package_size = 15;
                          var import_id = null;

                          var handle_error = function( response ) {
                              return $q.reject( response );
                          };

                          $scope.report = {};

                          var creneaux_emploi_du_temps = _($scope.creneaux).select( function( creneau ) {
                              return creneau.ready && creneau.is_displayed;
                          } );

                          // Log import
                          return $http.post( APP_PATH + '/api/import/log/start/?uai=' + $scope.pronote.UAI, { uai: $scope.pronote.UAI, type: 'client ' + VERSION, comment: '' } )
                              .then(
                                  function success( response ) {
                                      import_id = response.data.id;

                                      // Create Etablissement
                                      var ct_etablissement = new Etablissements( { uai: $scope.pronote.UAI,
                                                                                   date_premier_jour_premiere_semaine: new Date( $scope.pronote.AnneeScolaire[0].DatePremierJourSemaine1 ),
                                                                                   debut_annee_scolaire: new Date( $scope.pronote.AnneeScolaire[0].DateDebut ),
                                                                                   fin_annee_scolaire: new Date( $scope.pronote.AnneeScolaire[0].DateFin )
                                                                                 } );
                                      return ct_etablissement.$save();
                                  },
                                  handle_error
                              )
                              .then(
                                  function success( response ) {
                                      $scope.report.etablissement = response;

                                      // Create CahierDeTextes
                                      var preprocess_cahiers_de_textes = function( liste_regroupements ) {
                                          return _.chain(liste_regroupements)
                                              .reject( function( regroupement ) { return _(regroupement.laclasse).isUndefined(); } )
                                              .map( function( regroupement ) {
                                                  return { label: regroupement.laclasse.libelle_aaf,
                                                           regroupement_id: regroupement.laclasse.id,
                                                           debut_annee_scolaire: new Date( $scope.pronote.AnneeScolaire[0].DateDebut ),
                                                           fin_annee_scolaire: new Date( $scope.pronote.AnneeScolaire[0].DateFin ) };
                                              } )
                                              .value();
                                      };
                                      var regroupements = preprocess_cahiers_de_textes( $scope.pronote.classes );
                                      regroupements.push( preprocess_cahiers_de_textes( $scope.pronote.groupes_eleves ) );
                                      regroupements = _(regroupements).flatten();

                                      return $http.post( APP_PATH + '/api/cahiers_de_textes/bulk', { cahiers_de_textes: regroupements } );
                                  },
                                  handle_error
                              )
                              .then(
                                  function success( response ) {
                                      $scope.report.cahiers_de_textes = response.data;

                                      // Create Salle
                                      toastr.info('Création des salles');
                                      var salles_to_import = _($scope.pronote.salles)
                                          .map( function( salle ) {
                                              return { uai: $scope.pronote.UAI,
                                                       identifiant: salle.Ident,
                                                       nom: salle.Nom };
                                          } );

                                      return $http.post( APP_PATH + '/api/salles/bulk', { salles: salles_to_import } );
                                  },
                                  handle_error
                              )
                              .then(
                                  function success( response ) {
                                      $scope.report.salles = response.data;

                                      // Create Creneaux
                                      var creneaux_to_import = creneaux_emploi_du_temps.map( function( creneau ) {
                                          var heure_debut = Utils.libelleHeure_to_Moment( $scope.pronote.plages_horaires[ creneau.NumeroPlaceDebut ].LibelleHeureDebut );

                                          var pre_creneau = { import_id: import_id,
                                                              jour_de_la_semaine: parseInt( creneau.Jour ),
                                                              heure_debut: heure_debut.toISOString(),
                                                              heure_fin: heure_debut.add( parseInt( creneau.NombrePlaces ) * parseInt( $scope.pronote.GrilleHoraire[0].DureePlace ), 'minutes' ).toISOString(),
                                                              matiere_id: $scope.pronote.matieres[ creneau.Matiere.Ident ].laclasse.id };

                                          if ( _(creneau).has('Salle') ) {
                                              pre_creneau.salle_id = _($scope.report.salles).find( { identifiant: creneau.Salle.Ident } ).id;
                                              pre_creneau.semainier_salle = parseInt( creneau.Salle.Semaines );
                                          }

                                          if ( _(creneau).has('Classe') ) {
                                              pre_creneau.regroupement_id = $scope.pronote.classes[ creneau.Classe.Ident ].laclasse.id;
                                              pre_creneau.semainier_regroupement = parseInt( creneau.Classe.Semaines );
                                          } else {
                                              pre_creneau.regroupement_id = $scope.pronote.groupes_eleves[ creneau.Groupe.Ident ].laclasse.id;
                                              pre_creneau.semainier_regroupement = parseInt( creneau.Groupe.Semaines );
                                          }

                                          return pre_creneau;
                                      } );

                                      toastr.info('Import de ' + creneaux_to_import.length + ' créneaux');

                                      return $http.post( APP_PATH + '/api/creneaux_emploi_du_temps/bulk/',
                                                         { uai: $scope.pronote.UAI,
                                                           creneaux_emploi_du_temps: creneaux_to_import } );
                                  },
                                  handle_error
                              )
                              .then(
                                  function success( response ) {
                                      $scope.report.creneaux = response.data;

                                      return $q.resolve( $scope.report );
                                  },
                                  handle_error
                              );
                      };

                      $scope.match_this = function( item, uai ) {
                          var laclasse_id = _(item.laclasse).has('ent_id') ? item.laclasse.ent_id : item.laclasse.id;

                          var m = new Matchable({ uai: uai,
                                                  hash_item: hash_me( item ),
                                                  id_annuaire: laclasse_id });
                          m.$save().then( function() {
                              update_creneaux_readiness();
                          } );
                      };
                      // FIXME
                      $scope.unmatch_this = function( item, uai ) {
                          Matchable.$delete({ uai: uai,
                                              hash_item: hash_me( item ) })
                              .then( function() {
                                  item.laclasse = null;
                                  update_creneaux_readiness();
                              } );
                      };

                      $scope.process_load = function( fichier ) {
                          swal( { title: "Chargement des données...",
                                  text: "traitement en cours",
                                  type: "info",
                                  showLoaderOnConfirm: true,
                                  onOpen: function(){
                                      swal.clickConfirm();
                                  },
                                  preConfirm: function() {
                                      return new Promise( function( resolve ) {
                                          load_data( fichier ).then(
                                              function success( response ) {
                                                  swal.closeModal();
                                              },
                                              function error( response ) {
                                                  console.log( response );
                                                  swal.closeModal();
                                                  swal({ title: 'Erreur :(',
                                                         text: response.data.error,
                                                         type: 'error' });

                                              }
                                          );
                                      } );
                                  },
                                  allowOutsideClick: false } );
                      };

                      $scope.validate_matches = function() {
                          $scope.step++;
                      };

                      $scope.process_import = function() {
                          swal( { title: "Import des données...",
                                  text: "traitement en cours",
                                  type: "info",
                                  showLoaderOnConfirm: true,
                                  allowOutsideClick: false,
                                  onOpen: function(){
                                      swal.clickConfirm();
                                  },
                                  preConfirm: function() {
                                      return new Promise( function( resolve ) {
                                          import_data().then(
                                              function success( response ) {
                                                  swal.closeModal();
                                                  $scope.step = 0;
                                                  swal({ title: "Import terminé",
                                                         html: "",
                                                         type: 'success' });
                                              },
                                              function error( response ) {
                                                  console.log( response );
                                                  swal.closeModal();
                                                  swal({ title: 'Erreur :(',
                                                         text: response.data.error,
                                                         type: 'error' });
                                              }
                                          );
                                      } );
                                  }
                                } );
                      };
                  } ] );
