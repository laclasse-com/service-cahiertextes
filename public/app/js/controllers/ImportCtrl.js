'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('ImportCtrl',
                [ '$scope', '$http', '$locale', '$sce', '$filter', 'toastr', 'fileUpload', 'moment', 'APP_PATH', 'SEMAINES_VACANCES', 'ZONE', 'VERSION', 'Annuaire', 'Utils',
                  'Etablissements', 'PlagesHoraires', 'Salles', 'CreneauxEmploiDuTemps', 'CahiersDeTextes',
                  'current_user',
                  function ( $scope, $http, $locale, $sce, $filter, toastr, fileUpload, moment, APP_PATH, SEMAINES_VACANCES, ZONE, VERSION, Annuaire, Utils,
                             Etablissements, PlagesHoraires, Salles, CreneauxEmploiDuTemps, CahiersDeTextes,
                             current_user ) {
                      var toastr_config = { autoDismiss: false,
                                            allowHtml: true };

                      var libelleHeure_to_Date = function( libelle ) {
                          var heure = libelle.split(':').map( function( i ) { return parseInt( i ); } );

                          return new Date( 2001, 0, 1, heure[0], heure[1], heure[2] );
                      };

                      $scope.scope = $scope;
                      $scope.jours_de_la_semaine = $locale.DATETIME_FORMATS.DAY;
                      $scope.annee = $locale.DATETIME_FORMATS.MONTH;
                      $scope.fichier = null;
                      $scope.matcheable_data = [];
                      $scope.filtered_import = false;
                      $scope.ui = { show_detailed_creneaux: false,
                                    display_ready: true,
                                    display_problems: true,
                                    loading_file: false,
                                    processing: false,
                                    sortCreneauxBy: [ 'Jour' ],
                                    sort_creneaux_by: function( criteria ) {
                                        $scope.ui.sortCreneauxBy = $scope.ui.sortCreneauxBy[0] === criteria[0] ?  _(criteria).map( function( sub_criteria ) { return '-' + sub_criteria; } ) : criteria;
                                    } };

                      var get_etablissement_summary = function() {
                          Etablissements.get( { uai: current_user.profil_actif.etablissement_code_uai } ).$promise.then( function( response ) {
                              $scope.etablissement_summary = response;
                              _($scope.etablissement_summary.imports).each( function( i ) { i.date_import = new Date( i.date_import ); } );
                          } );
                      };
                      get_etablissement_summary();

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

                              if ( _(criteria.enseignants).isEmpty() ) {
                                  creneau.is_displayed = creneau.is_displayed && !_(creneau).has( 'Professeur' );
                              } else {
                                  creneau.is_displayed = creneau.is_displayed &&
                                      _(creneau).has( 'Professeur' ) &&
                                      _.chain(criteria.enseignants).pluck( 'Ident' ).includes( creneau.Professeur.Ident ).value();
                              }

                              return creneau.is_displayed;
                          };
                      };

                      // ********** counters
                      $scope.update_counters = function() {
                          var filtered_creneaux = $filter('filter')( $scope.creneaux, $scope.filter_creneau( $scope.ui, $scope.selected ) );
                          $scope.counters = {};

                          $scope.counters.creneaux = $scope.creneaux.length;
                          $scope.counters.creneaux_broken = _($scope.pronote.Cours[0].Cours).select( function( cours ) { return !_(cours).has( 'Matiere' ) || !_(cours).has( 'Professeur' ) || ( !_(cours).has( 'Classe' ) && !_(cours).has( 'Groupe' ) ); } ).length;
                          $scope.counters.creneaux_not_ready = _($scope.creneaux).where({ ready: false }).length;
                          $scope.counters.creneaux_ready = $scope.counters.creneaux - $scope.counters.creneaux_not_ready;

                          $scope.counters.filtered_creneaux = filtered_creneaux.length;
                          $scope.counters.filtered_creneaux_not_ready = _(filtered_creneaux).where({ ready: false }).length;
                          $scope.counters.filtered_creneaux_ready = $scope.counters.filtered_creneaux - $scope.counters.filtered_creneaux_not_ready;

                          $scope.counters.percent_creneaux_ready = $scope.filtered_import ? $scope.counters.filtered_creneaux_ready / $scope.counters.filtered_creneaux : $scope.counters.creneaux_ready / $scope.counters.creneaux;
                      };
                      // ********** /counters

                      // ********** readiness
                      $scope.update_creneaux_readiness = function() {
                          _($scope.creneaux).each( function( creneau ) {
                              creneau.readiness = { matiere: !_($scope.pronote.matieres[ creneau.Matiere.Ident ].laclasse).isUndefined(),
                                                    salle: !_(creneau.Salle).isUndefined(),
                                                    enseignant: !_($scope.pronote.enseignants[ creneau.Professeur.Ident ].laclasse).isUndefined(),
                                                    classe: _(creneau).has('Classe') && !_($scope.pronote.classes[ creneau.Classe.Ident ].laclasse).isUndefined(),
                                                    groupe_eleve: _(creneau).has('Groupe') && !_($scope.pronote.groupes_eleves[ creneau.Groupe.Ident ].laclasse).isUndefined() };

                              creneau.ready = creneau.readiness.matiere && creneau.readiness.enseignant && ( creneau.readiness.classe || creneau.readiness.groupe_eleve );
                          } );

                          $scope.update_counters();
                      };
                      // ********** /readiness

                      // ACTIONS
                      $scope.load_data = function( fichier ) {
                          var toasts = {
                              file_loading: toastr.info( '', '<i class="fa fa-spinner fa-pulse"></i> Chargement du fichier', toastr_config )
                          };

                          var started_at = moment();
                          $scope.pronote = false;
                          $scope.ui.loading_file = true;
                          $scope.matcheable_data = [];

                          fileUpload.uploadFileToUrl( fichier, APP_PATH + '/api/v1/import/pronote/decrypt' )
                              .success( function( data, status, headers, config ) {
                                  toastr.clear( toasts.file_loading );
                                  console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : decrypted data received' )

                                  // 1. Récupérer le fichier Pronote décrypté
                                  $scope.pronote = data;
                                  $scope.pronote.GrilleHoraire[0].DureePlace = parseInt( $scope.pronote.GrilleHoraire[0].DureePlace );

                                  toasts.load_etab_data = toastr.info( '', '<i class="fa fa-spinner fa-pulse"></i> Chargement des informations de l\'établissement', toastr_config );

                                  // 2. Récupérer toutes les infos de l'établissement et toutes les matières
                                  Annuaire.get_etablissement( $scope.pronote.UAI )
                                      .then( function( response ) {
                                          toastr.clear( toasts.load_etab_data );

                                          console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : etablissement\'s data received' )

                                          $scope.etablissement = { teachers: _(response.data.users).select( function( user ) { return _(user.profils).includes( 'ENS' ) || _(user.profils).includes( 'DOC' ); } ),
                                                                   classes: _(response.data.groups).where( { type_regroupement_id: 'CLS' } ),
                                                                   groupes_eleves: _(response.data.groups).select( { type_regroupement_id: 'GRP' } ) };

                                          // UPPERCASE ALL THE THINGS!!!!!
                                          _($scope.etablissement.teachers).each( function( user ) {
                                              user.firstname = user.firstname.toUpperCase();
                                              user.lastname = user.lastname.toUpperCase();
                                              user.displayed_label = user.lastname + ' ' + user.firstname.toLocaleLowerCase();
                                          } );
                                          _($scope.etablissement.groupes_eleves).each( function( regroupement ) {
                                              regroupement.libelle_aaf = regroupement.libelle_aaf.toUpperCase();
                                              regroupement.displayed_label = regroupement.libelle_aaf;
                                          } );
                                          _($scope.etablissement.classes).each( function( regroupement ) {
                                              regroupement.libelle_aaf = regroupement.libelle_aaf.toUpperCase();
                                              regroupement.displayed_label = regroupement.libelle_aaf;
                                          } );
                                          console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : all things UPPERCASED!' )

                                          // 3.2 Enseignants
                                          _($scope.pronote.Professeurs[0].Professeur)
                                              .each( function( enseignant ) {
                                                  enseignant.displayed_label = enseignant.Prenom + ' ' + enseignant.Nom;
                                                  enseignant.laclasse = _($scope.etablissement.teachers).findWhere( { lastname: enseignant.Nom.toUpperCase(),
                                                                                                                      firstname: enseignant.Prenom.toUpperCase() } );
                                                  enseignant.edit = _(enseignant.laclasse).isUndefined();
                                                  if ( !enseignant.edit ) {
                                                      enseignant.laclasse.displayed_label = enseignant.laclasse.lastname + ' ' + enseignant.laclasse.firstname.toLocaleLowerCase();
                                                  }
                                              } );
                                          console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : matched Enseignants' )

                                          // 3.3 Classes et Groupes
                                          _($scope.pronote.Classes[0].Classe)
                                              .each( function( regroupement ) {
                                                  regroupement.displayed_label = regroupement.Nom;
                                                  regroupement.laclasse = _($scope.etablissement.classes).findWhere( { libelle_aaf: regroupement.Nom.toUpperCase() } );
                                                  regroupement.edit = _(regroupement.laclasse).isUndefined();
                                                  if ( !regroupement.edit ) {
                                                      regroupement.laclasse.displayed_label = regroupement.laclasse.libelle_aaf;
                                                  }
                                              } );
                                          console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : matched Classes' )

                                          _($scope.pronote.Groupes[0].Groupe)
                                              .each( function( regroupement ) {
                                                  regroupement.displayed_label = regroupement.Nom;
                                                  regroupement.laclasse = _($scope.etablissement.groupes_eleves).findWhere( { libelle_aaf: regroupement.Nom.toUpperCase() } );
                                                  regroupement.edit = _(regroupement.laclasse).isUndefined();
                                                  if ( !regroupement.edit ) {
                                                      regroupement.laclasse.displayed_label = regroupement.laclasse.libelle_aaf;
                                                  }
                                              } );
                                          console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : matched Groupes' )

                                          // 4. treating Cours
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

                                          $scope.creneaux = _.chain($scope.pronote.Cours[0].Cours)
                                              .map( function( cours ) {
                                                  return _.chain(cours.Matiere).map( function( matiere ) {
                                                      return _(cours.Professeur).map( function( enseignant ) {
                                                          var compute_cours = function( type_regroupement ) {
                                                              return function( regroupement ) {
                                                                  var fix_semainier = function( semainier_pronote ) {
                                                                      var pivot = 17;
                                                                      var bsemainier = parseInt( semainier_pronote ).toString( 2 );
                                                                      bsemainier = Utils.padEnd( bsemainier, 53, '0' );

                                                                      var fixed_bsemainier = bsemainier.slice( pivot, bsemainier.length ) + bsemainier.substr( 0, pivot );
                                                                      var fixed_semainier = parseInt( fixed_bsemainier, 2 );

                                                                      return fixed_semainier;
                                                                  };

                                                                  var this_cours = angular.copy( cours );
                                                                  this_cours.is_displayed = true;
                                                                  this_cours.Matiere = matiere;
                                                                  this_cours.Professeur = enseignant;
                                                                  this_cours.Professeur.Semaines = fix_semainier( this_cours.Professeur.Semaines );

                                                                  if ( type_regroupement === 'Classe' ) {
                                                                      this_cours.Classe = regroupement;
                                                                      this_cours.Classe.Semaines = fix_semainier( this_cours.Classe.Semaines );
                                                                  } else {
                                                                      this_cours.Groupe = regroupement;
                                                                      this_cours.Groupe.Semaines = fix_semainier( this_cours.Groupe.Semaines );
                                                                  }

                                                                  if ( _(cours).has('Salle') ) {
                                                                      return _(cours.Salle).map( function( salle ) {
                                                                          this_cours.Salle = salle;
                                                                          this_cours.Salle.Semaines = fix_semainier( this_cours.Salle.Semaines );

                                                                          return this_cours;
                                                                      } );
                                                                  } else {
                                                                      return this_cours;
                                                                  }
                                                              };
                                                          };
                                                          return [
                                                              _(cours.Classe).map( compute_cours( 'Classe' ) ),
                                                              _(cours.Groupe).map( compute_cours( 'Groupe' ) )
                                                          ];
                                                      } );
                                                  } )
                                                      .flatten()
                                                      .uniq()
                                                      .value();
                                              } )
                                              .flatten()
                                              .value();
                                          console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : Cours treated' )

                                          $scope.pronote.enseignants = Utils.groupByKey( $scope.pronote.Professeurs[0].Professeur, 'Ident' );
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
                                          $scope.matcheable_data.push( { title: 'Enseignants',
                                                                         pronote: $scope.pronote.enseignants,
                                                                         annuaire: $scope.etablissement.teachers } );

                                          toasts.load_matieres = toastr.info( '', '<i class="fa fa-spinner fa-pulse"></i> Chargement des matières officielles', toastr_config );

                                          Annuaire.get_matieres()
                                              .then( function( response ) {
                                                  toastr.clear( toasts.load_matieres );
                                                  $scope.matieres = _(response.data).map( function( matiere ) {
                                                      matiere.libelle_long = matiere.libelle_long.toUpperCase();
                                                      matiere.displayed_label = matiere.libelle_long;

                                                      return matiere;
                                                  } );

                                                  // 3. Matcher les 2
                                                  // 3.1 Matières
                                                  _($scope.pronote.Matieres[0].Matiere)
                                                      .each( function( matiere ) {
                                                          matiere.displayed_label = matiere.Libelle;
                                                          matiere.laclasse = _($scope.matieres).findWhere( { libelle_long: matiere.Libelle.toUpperCase() } );
                                                          matiere.edit = _(matiere.laclasse).isUndefined();
                                                          if ( !matiere.edit ) {
                                                              matiere.laclasse.displayed_label = matiere.laclasse.libelle_long;
                                                          }
                                                      } );
                                                  console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : matched Matieres' )

                                                  $scope.pronote.matieres = Utils.groupByKey( $scope.pronote.Matieres[0].Matiere, 'Ident' );
                                                  console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : $scope.pronote populated' )
                                                  $scope.matcheable_data.push( { title: 'Matières',
                                                                                 pronote: $scope.pronote.matieres,
                                                                                 annuaire: $scope.matieres } );

                                                  _($scope.matcheable_data).each( function( dataset ) {
                                                      dataset.total = function() { return _(dataset.pronote).size(); };
                                                      dataset.unmatched = function() { return _(dataset.pronote).where( { laclasse: undefined } ).length; };
                                                      dataset.percent_valid = function() { return ( dataset.total() - dataset.unmatched() ) / dataset.total(); };
                                                  } );

                                                  $scope.selected = { matieres: $scope.pronote.Matieres[0].Matiere,
                                                                      enseignants: $scope.pronote.Professeurs[0].Professeur,
                                                                      classes: $scope.pronote.Classes[0].Classe,
                                                                      groupes: $scope.pronote.Groupes[0].Groupe };

                                                  $scope.update_creneaux_readiness();

                                                  $scope.$watchCollection( 'selected', $scope.update_counters );

                                                  $scope.ui.loading_file = false;
                                                  console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : finished!' )
                                              } );
                                      } );
                              } );
                      };

                      $scope.process_import = function() {
                          var bulk_package_size = 15;
                          $scope.ui.processing = true;

                          var creneaux_emploi_du_temps = _($scope.creneaux).select( function( creneau ) {
                              return creneau.ready && ( !$scope.filtered_import || ( $scope.filtered_import && creneau.is_displayed ) );
                          } );

                          // Log import
                          $http.post(  APP_PATH + '/api/v1/import/log/start', { uai: $scope.pronote.UAI,
                                                                                type: 'client ' + VERSION,
                                                                                comment: 'nan rien' } );

                          // Create Etablissement
                          var ct_etablissement = new Etablissements( {
                              uai: $scope.pronote.UAI,
                              date_premier_jour_premiere_semaine: new Date( $scope.pronote.AnneeScolaire[0].DatePremierJourSemaine1 ),
                              debut_annee_scolaire: new Date( $scope.pronote.AnneeScolaire[0].DateDebut ),
                              fin_annee_scolaire: new Date( $scope.pronote.AnneeScolaire[0].DateFin )
                          } );
                          ct_etablissement.$save();
                          toastr.info( 'Etablissement mis à jour', 'Import en cours' );

                          // // Create CahierDeTextes
                          $scope.expected_cahiers_de_textes = _($scope.pronote.classes).size() + _($scope.pronote.groupes_eleves).size();

                          var preprocess_cahiers_de_textes = function( liste_regroupements ) {
                              return _.chain(liste_regroupements)
                                  .reject( function( regroupement ) { return _(regroupement.laclasse).isUndefined(); } )
                                  .map( function( regroupement ) {
                                      return {
                                          label: regroupement.laclasse.libelle_aaf,
                                          regroupement_id: regroupement.laclasse.id,
                                          debut_annee_scolaire: new Date( $scope.pronote.AnneeScolaire[0].DateDebut ),
                                          fin_annee_scolaire: new Date( $scope.pronote.AnneeScolaire[0].DateFin )
                                      };
                                  } )
                                  .value();
                          };
                          var regroupements = preprocess_cahiers_de_textes( $scope.pronote.classes );
                          regroupements.push( preprocess_cahiers_de_textes( $scope.pronote.groupes_eleves ) );
                          regroupements = _(regroupements).flatten();
                          $scope.cahiers_de_textes_created = [];
                          $scope.cahiers_de_textes_created = 0;

                          while ( regroupements.length > 0 ) {
                              var slice_of_regroupements = regroupements.splice( 0, bulk_package_size );
                              CahiersDeTextes.bulk( { cahiers_de_textes: slice_of_regroupements } ).$promise
                                  .then( function( response ) {
                                      $scope.cahiers_de_textes_created += response;
                                      toastr.info( _($scope.cahiers_de_textes_created).size() + ' CahierDeTextes', 'Import en cours' );
                                  } );
                          }

                          // Create Salle
                          $scope.expected_salles = _($scope.pronote.salles).size();

                          // FIXME: Hoping that it doesn't exceed Puma's POST size limit...
                          Salles.bulk( { salles: _($scope.pronote.salles)
                                         .map( function( salle ) {
                                             return {
                                                 uai: $scope.pronote.UAI,
                                                 identifiant: salle.Ident,
                                                 nom: salle.Nom
                                             };
                                         } )
                                       } ).$promise.then( function( response ) {
                                           $scope.salles_created = response;

                                           toastr.info( _($scope.salles_created).size() + ' Salles', 'Import en cours' );

                                           var creneaux_filter = $scope.filter_creneau( true, $scope.selected );

                                           // Create Creneaux
                                           var creneaux_to_import = creneaux_emploi_du_temps.map( function( creneau ) {
                                               var heure_debut = libelleHeure_to_Date( $scope.pronote.plages_horaires[ creneau.NumeroPlaceDebut ].LibelleHeureDebut );
                                               var pre_creneau = { jour_de_la_semaine: parseInt( creneau.Jour ),
                                                                   heure_debut: heure_debut,
                                                                   heure_fin: moment( heure_debut ).add( parseInt( creneau.NombrePlaces ) * parseInt( $scope.pronote.GrilleHoraire[0].DureePlace ), 'minutes' ).toDate(),
                                                                   matiere_id: $scope.pronote.matieres[ creneau.Matiere.Ident ].laclasse.id,
                                                                   enseignant_id: $scope.pronote.enseignants[ creneau.Professeur.Ident ].laclasse.ent_id,
                                                                   semaines_de_presence_enseignant: parseInt( creneau.Professeur.Semaines ) };

                                               if ( _(creneau).has('Salle') ) {
                                                   pre_creneau.salle_id = _($scope.salles_created).find( { identifiant: creneau.Salle.Ident } ).id;
                                                   pre_creneau.semaines_de_presence_salle = parseInt( creneau.Salle.Semaines );
                                               }

                                               if ( _(creneau).has('Classe') ) {
                                                   pre_creneau.regroupement_id = $scope.pronote.classes[ creneau.Classe.Ident ].laclasse.id;
                                                   pre_creneau.semaines_de_presence_regroupement = parseInt( creneau.Classe.Semaines );
                                               } else {
                                                   pre_creneau.regroupement_id = $scope.pronote.groupes_eleves[ creneau.Groupe.Ident ].laclasse.id;
                                                   pre_creneau.semaines_de_presence_regroupement = parseInt( creneau.Groupe.Semaines );
                                               }

                                               return pre_creneau;
                                           } );

                                           $scope.creneaux_created = [];
                                           $scope.counters.creneaux_created = 0;

                                           while ( creneaux_to_import.length > 0 ) {
                                               CreneauxEmploiDuTemps.bulk( {
                                                   uai: $scope.pronote.UAI,
                                                   creneaux_emploi_du_temps: creneaux_to_import.splice( 0, bulk_package_size )
                                               } ).$promise
                                                   .then( function( response ) {
                                                       $scope.creneaux_created.push( response );
                                                       toastr.info( _($scope.creneaux_created).size() + ' Créneaux', 'Import en cours' );

                                                       get_etablissement_summary(); // not ideal placement
                                                   } );
                                           }
                                       } );

                          $scope.ui.processing = false;
                      };
                  } ] );
