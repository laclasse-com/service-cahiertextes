'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('ImportCtrl',
                [ '$scope', '$http', '$locale', '$sce', 'toastr', 'APP_PATH', 'SEMAINES_VACANCES', 'ZONE', 'Annuaire', 'fileUpload', 'moment',
                  'Etablissements', 'PlagesHoraires', 'Salles', 'CreneauxEmploiDuTemps', 'CahiersDeTextes',
                  'current_user',
                  function ( $scope, $http, $locale, $sce, toastr, APP_PATH, SEMAINES_VACANCES, ZONE, Annuaire, fileUpload, moment,
                             Etablissements, PlagesHoraires, Salles, CreneauxEmploiDuTemps, CahiersDeTextes,
                             current_user ) {
                      $scope.scope = $scope;

                      var groupByKey = function( array, key ) {
                          return _.chain( array ).map( function( i ) { return i[ key ]; } ).object( array ).value();
                      };

                      $scope.jours_de_la_semaine = $locale.DATETIME_FORMATS.DAY;
                      $scope.pronote = false;
                      $scope.etablissement = false;
                      $scope.matieres = false;
                      $scope.fichier = null;
                      $scope.loading_file = false;
                      $scope.processing = false;
                      $scope.matcheable_data = [];
                      $scope.problems_only = false;
                      $scope.filtered_import = false;
                      $scope.ui = { is_accordion_open: false };

                      Annuaire.get_matieres()
                          .then( function( response ) {
                              $scope.matieres = response.data;

                              _($scope.matieres).each( function( matiere ) {
                                  matiere.libelle_long = matiere.libelle_long.toUpperCase();
                                  matiere.displayed_label = matiere.libelle_long;
                              } );
                          } );

                      // ********** semainiers
                      $scope.annee = $locale.DATETIME_FORMATS.MONTH;
                      $scope.jours = _($locale.DATETIME_FORMATS.DAY).indexBy( function( jour ) { return _($locale.DATETIME_FORMATS.DAY).indexOf( jour ); } );

                      var padEnd = function( string, target_length, filler ) {
                          if ( string.length >= target_length ) {
                              return string;
                          } else {
                              var pad = '';
                              _( (target_length - string.length) / filler.length ).times( function() { pad += filler; } );

                              return (string + pad).substr( 0, target_length );
                          }
                      };
                      var what_month = function( n_week ) {
                          var now = moment();
                          var year = now.year();
                          if ( ( n_week < 36 ) && ( now.month() > 7 ) ) {
                              year++;
                          } else if ( now.month() < 7 ) {
                              year--;
                          }
                          return moment( year ).isoWeek( n_week ).month();
                      };
                      var sont_ce_les_vacances = function( i_semaine, zone ) {
                          return SEMAINES_VACANCES[ zone ].indexOf( i_semaine ) != -1;
                      };

                      var overlay_semainier = _.chain( _.range(1, 52) )
                          .map( function( s ) { return { semaine: s,
                                                         mois: what_month( s ) }; } )
                          .groupBy( function( s ) { return s.mois; } )
                          .toArray()
                          .map( function( semaines, i ) {
                              return { index: i > 7 ? i - 8 : i + 4,
                                       label: $scope.annee[ i ],
                                       semaines: semaines };
                          } )
                          .value();

                      var beautify_semainier = function( semainier ) {
                          var bsemainier = padEnd( semainier.toString( 2 ), 53, '0' );
                          var fixed_bsemainier = bsemainier.substr( 17 ) + bsemainier.substr( 0, 17 );

                          var html = '<div class="semainier-tooltip gris1">';
                          html += _.chain(overlay_semainier)
                              .sortBy( function( month ) { return month.index; } )
                              .map( function( month ) {
                                  var month_html = '<div class="month blanc"><h5 class="month-name gris4">' + month.label + '</h5>';

                                  month_html += _(month.semaines).map( function( week ) {
                                      var week_html = '<span class="week';
                                      if ( sont_ce_les_vacances( week.semaine, ZONE ) ) { week_html += ' gris1'; }
                                      if ( fixed_bsemainier[ week.semaine ] === '1' ) { week_html += ' orange-moins'; }
                                      week_html += '">' + week.semaine + '</span>';

                                      return week_html;
                                  } ).join('');

                                  month_html += '</div>';

                                  return month_html;
                              } )
                              .value()
                              .join('');
                          html += '<div class="clearfix"></div></div>';

                          return html; // $sce.trustAsHtml( html );
                      };
                      // ********** /semainiers
                      // ********** filtrage tableau créneaux
                      $scope.filter_creneau = function( problems_only, criteria ) {
                          return function( creneau ) {
                              if ( problems_only && !creneau.ready ) { return false; }

                              var is_displayed = true;
                              var extract_Ident = function( item ) { return item.Ident; };

                              if ( _(criteria.classes).isEmpty() && _(criteria.groupes).isEmpty() ) {
                                  is_displayed = is_displayed &&
                                      !_(creneau).has( 'Classe' ) &&
                                      !_(creneau).has( 'Groupe' );
                              } else if ( _(criteria.classes).isEmpty() && !_(criteria.groupes).isEmpty() ) {
                                  is_displayed = is_displayed &&
                                      !_(creneau).has( 'Classe' ) &&
                                      _(creneau).has( 'Groupe' ) &&
                                      _.intersection( _(creneau.Groupe).map( extract_Ident ), _(criteria.groupes).map( extract_Ident ) ).length > 0;
                              } else if ( !_(criteria.classes).isEmpty() && _(criteria.groupes).isEmpty() ) {
                                  is_displayed = is_displayed &&
                                      _(creneau).has( 'Classe' ) &&
                                      !_(creneau).has( 'Groupe' ) &&
                                      _.intersection( _(creneau.Classe).map( extract_Ident ), _(criteria.classes).map( extract_Ident ) ).length > 0;
                              } else {
                                  is_displayed = is_displayed &&
                                      ( (_(creneau).has( 'Groupe' ) && _.intersection( _(creneau.Groupe).map( extract_Ident ), _(criteria.groupes).map( extract_Ident ) ).length > 0) ||
                                        (_(creneau).has( 'Classe' ) && _.intersection( _(creneau.Classe).map( extract_Ident ), _(criteria.classes).map( extract_Ident ) ).length > 0 ) );
                              }
                              if ( !is_displayed ) { return false; }

                              if ( _(criteria.matieres).isEmpty() ) {
                                  is_displayed = is_displayed &&
                                      !_(creneau).has( 'Matiere' );
                              } else {
                                  is_displayed = is_displayed &&
                                      _(creneau).has( 'Matiere' ) &&
                                      _.intersection( _(creneau.Matiere).map( extract_Ident ), _(criteria.matieres).map( extract_Ident ) ).length > 0;
                              }
                              if ( !is_displayed ) { return false; }

                              if ( _(criteria.enseignants).isEmpty() ) {
                                  is_displayed = is_displayed &&
                                      !_(creneau).has( 'Professeur' );
                              } else {
                                  is_displayed = is_displayed &&
                                      _(creneau).has( 'Professeur' ) &&
                                      _.intersection( _(creneau.Professeur).map( extract_Ident ), _(criteria.enseignants).map( extract_Ident ) ).length > 0;
                              }

                              return is_displayed;
                          };
                      };
                      // ********** /filtrage tableau créneaux

                      $scope.identifie_objet = function( mrpni ) {
                          if ( _(mrpni).has('id_annuaire')
                               && !_(mrpni.id_annuaire).isNull()
                               && !_(mrpni.id_annuaire).isUndefined() ) {
                              $http.put( APP_PATH + '/api/v1/import/mrpni/' + mrpni.sha256 + '/est/' + mrpni.id_annuaire )
                                  .success( function() {
                                      mrpni.identified = true;
                                  });
                          }
                      };
                      $scope.identifie_massivement_objets = function( mrpnis ) {
                          _(mrpnis).each( function( mrpni ) {
                              $scope.identifie_objet( mrpni );
                          } );
                      };

                      $scope.load_data = function( fichier ) {
                          var started_at = moment();
                          $scope.pronote = false;
                          $scope.loading_file = true;

                          fileUpload.uploadFileToUrl( fichier, APP_PATH + '/api/v1/import/pronote/decrypt' )
                              .success( function( data, status, headers, config ) {
                                  console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : decrypted data received' )

                                  // 1. Récupérer le fichier Pronote décrypté
                                  $scope.pronote = data;
                                  $scope.pronote.GrilleHoraire[0].DureePlace = parseInt( $scope.pronote.GrilleHoraire[0].DureePlace );

                                  // 2. Récupérer toutes les infos de l'établissement et toutes les matières
                                  Annuaire.get_etablissement( $scope.pronote.UAI )
                                      .then( function( response ) {
                                          console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : etablissement\'s data received' )

                                          $scope.etablissement = { teachers: _(response.data.users).select( function( user ) { return _(user.profils).includes( 'ENS' ) || _(user.profils).includes( 'DOC' ); } ),
                                                                   classes: _(response.data.groups).where( { type_regroupement_id: 'CLS' } ),
                                                                   groupes_eleves: _(response.data.groups).select( { type_regroupement_id: 'GRP' } ) };

                                          // UPPERCASE ALL THE THINGS!!!!!
                                          _($scope.etablissement.teachers).each( function( user ) {
                                              user.firstname = user.firstname.toUpperCase();
                                              user.lastname = user.lastname.toUpperCase();
                                              user.displayed_label = user.lastname + ' ' + user.firstname;
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

                                          // 3.2 Enseignants
                                          _($scope.pronote.Professeurs[0].Professeur)
                                              .each( function( enseignant ) {
                                                  enseignant.displayed_label = enseignant.Prenom + ' ' + enseignant.Nom;
                                                  enseignant.laclasse = _($scope.etablissement.teachers).findWhere( { lastname: enseignant.Nom.toUpperCase(),
                                                                                                                      firstname: enseignant.Prenom.toUpperCase() } );
                                                  enseignant.edit = _(enseignant.laclasse).isUndefined();
                                                  if ( !enseignant.edit ) {
                                                      enseignant.laclasse.displayed_label = enseignant.laclasse.firstname + ' ' + enseignant.laclasse.lastname;
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

                                          // 4. assemble semainiers' HTML
                                          _($scope.pronote.Cours[0].Cours).each( function( creneau ) {
                                              _(creneau.Salle).each( function( node ) { node.displayed_semainier = beautify_semainier( node.Semaines ); } );
                                              _(creneau.Professeur).each( function( node ) { node.displayed_semainier = beautify_semainier( node.Semaines ); } );
                                              if ( _(creneau).has( 'Classe' ) ) {
                                                  _(creneau.Classe).each( function( node ) { node.displayed_semainier = beautify_semainier( node.Semaines ); } );
                                              }
                                              if ( _(creneau).has( 'Groupe' ) ) {
                                                  _(creneau.Groupe).each( function( node ) { node.displayed_semainier = beautify_semainier( node.Semaines ); } );
                                              }
                                          } );
                                          console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : semainiers assembled' )

                                          $scope.pronote.matieres = groupByKey( $scope.pronote.Matieres[0].Matiere, 'Ident' );
                                          $scope.pronote.enseignants = groupByKey( $scope.pronote.Professeurs[0].Professeur, 'Ident' );
                                          $scope.pronote.classes = groupByKey( $scope.pronote.Classes[0].Classe, 'Ident' );
                                          $scope.pronote.salles = groupByKey( $scope.pronote.Salles[0].Salle, 'Ident' );
                                          $scope.pronote.plages_horaires = groupByKey( $scope.pronote.GrilleHoraire[0].PlacesParJour[0].Place, 'Numero' );
                                          $scope.pronote.groupes_eleves = groupByKey( $scope.pronote.Groupes[0].Groupe, 'Ident' );
                                          console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : $scope.pronote populated' )

                                          $scope.matcheable_data.push( { title: 'Classes',
                                                                         pronote: $scope.pronote.classes,
                                                                         annuaire: $scope.etablissement.classes } );
                                          $scope.matcheable_data.push( { title: 'Groupes d\'élèves',
                                                                         pronote: $scope.pronote.groupes_eleves,
                                                                         annuaire: $scope.etablissement.groupes_eleves } );
                                          $scope.matcheable_data.push( { title: 'Enseignants',
                                                                         pronote: $scope.pronote.enseignants,
                                                                         annuaire: $scope.etablissement.teachers } );
                                          $scope.matcheable_data.push( { title: 'Matières',
                                                                         pronote: $scope.pronote.matieres,
                                                                         annuaire: $scope.matieres } );

                                          $scope.score_creneaux_update_counters(  );
                                          console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : scores of creneaux updated' )

                                          $scope.selected = { matieres: $scope.pronote.Matieres[0].Matiere,
                                                              enseignants: $scope.pronote.Professeurs[0].Professeur,
                                                              classes: $scope.pronote.Classes[0].Classe,
                                                              groupes: $scope.pronote.Groupes[0].Groupe };

                                          $scope.loading_file = false;
                                          console.log( ( ( moment() - started_at ) / 1000.0 ) + 's : finished!' )
                                      } );
                              } );
                      };

                      $scope.score_creneaux_update_counters = function(  ) {
                          _($scope.pronote.Cours[0].Cours).each( function( creneau ) {
                              creneau.readiness = { matiere: !_($scope.pronote.matieres[ creneau.Matiere[0].Ident ].laclasse).isUndefined(),
                                                    enseignant: _(creneau).has('Professeur') && _(creneau.Professeur).reduce( function( memo, enseignant ) { return memo && !_($scope.pronote.enseignants[ enseignant.Ident ].laclasse).isUndefined(); }, true ),
                                                    classe: _(creneau).has('Classe') && _(creneau.Classe).reduce( function( memo, classe ) { return memo && !_($scope.pronote.classes[ classe.Ident ].laclasse).isUndefined(); }, !_(creneau.Classe).isUndefined() ),
                                                    groupe_eleve: _(creneau).has('Groupe') && _(creneau.Groupe).reduce( function( memo, groupe ) { return memo && !_($scope.pronote.groupes_eleves[ groupe.Ident ].laclasse).isUndefined(); }, !_(creneau.Groupe).isUndefined() ) };

                              creneau.ready = creneau.readiness.matiere && creneau.readiness.enseignant && ( creneau.readiness.classe || creneau.readiness.groupe_eleve );
                          } );

                          var count_expected_creneaux = function( creneaux ) {
                              return _(creneaux).reduce( function( memo, creneau ) {
                                  var n_creneaux =  memo;
                                  var before = memo;

                                  if ( !_(creneau.Matiere).isUndefined() ) { n_creneaux += creneau.Matiere.length; }
                                  if ( n_creneaux == before ) { return memo; } else { before = n_creneaux; }

                                  if ( !_(creneau.Professeur).isUndefined() ) { n_creneaux += creneau.Professeur.length; }
                                  if ( n_creneaux == before ) { return memo; } else { before = n_creneaux; }

                                  if ( !_(creneau.Salle).isUndefined() ) { n_creneaux += creneau.Salle.length; }
                                  if ( n_creneaux == before ) { return memo; } else { before = n_creneaux; }

                                  if ( !_(creneau.Classe).isUndefined() ) { n_creneaux += creneau.Classe.length; }
                                  if ( !_(creneau.Groupe).isUndefined() ) { n_creneaux += creneau.Groupe.length; }
                                  if ( n_creneaux == before ) { return memo; } else { before = n_creneaux; }

                                  return n_creneaux; }, 0 );
                          };
                          $scope.nb_expected_creneaux = count_expected_creneaux( $scope.pronote.Cours[0].Cours );
                          $scope.nb_expected_creneaux_ready = count_expected_creneaux( _($scope.pronote.Cours[0].Cours).where( { ready: true } ) );

                          _($scope.matcheable_data).each( function( dataset ) {
                              switch( dataset.title ) {
                              case 'Matières':
                                  dataset.nb_total = $scope.pronote.Matieres[0].Matiere.length;
                                  dataset.nb_unmatched = _($scope.pronote.Matieres[0].Matiere).where( { laclasse: undefined } ).length;
                                  break;
                              case 'Enseignants':
                                  dataset.nb_total = $scope.pronote.Professeurs[0].Professeur.length;
                                  dataset.nb_unmatched = _($scope.pronote.Professeurs[0].Professeur).where( { laclasse: undefined } ).length;
                                  break;
                              case 'Classes':
                                  dataset.nb_total = $scope.pronote.Classes[0].Classe.length;
                                  dataset.nb_unmatched = _($scope.pronote.Classes[0].Classe).where( { laclasse: undefined } ).length;
                                  break;
                              case 'Groupes d\'élèves':
                                  dataset.nb_total = $scope.pronote.Groupes[0].Groupe.length;
                                  dataset.nb_unmatched = _($scope.pronote.Groupes[0].Groupe).where( { laclasse: undefined } ).length;
                                  break;
                              }
                          } );
                      };

                      var libelleHeure_to_Date = function( libelle ) {
                          var heure = libelle.split(':').map( function( i ) { return parseInt( i ); } );

                          return new Date( 2001, 0, 1, heure[0], heure[1], heure[2] );
                      };

                      $scope.process_import = function() {
                          var bulk_package_size = 15;
                          $scope.processing = true;

                          // Create Etablissement
                          var ct_etablissement = new Etablissements( {
                              uai: $scope.pronote.UAI,
                              date_premier_jour_premiere_semaine: new Date( $scope.pronote.AnneeScolaire[0].DatePremierJourSemaine1 ),
                              debut_annee_scolaire: new Date( $scope.pronote.AnneeScolaire[0].DateDebut ),
                              fin_annee_scolaire: new Date( $scope.pronote.AnneeScolaire[0].DateFin )
                          } );
                          ct_etablissement.$save();

                          // // Create CahierDeTextes
                          $scope.nb_expected_cahiers_de_textes = _($scope.pronote.classes).size() + _($scope.pronote.groupes_eleves).size();

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
                          $scope.nb_cahiers_de_textes_created = 0;
                          // TODO: filter based on selected.classes/groupes if needed

                          while ( regroupements.length > 0 ) {
                              var slice_of_regroupements = regroupements.splice( 0, bulk_package_size );
                              CahiersDeTextes.bulk( { cahiers_de_textes: slice_of_regroupements } ).$promise
                                  .then( function( response ) {
                                      $scope.cahiers_de_textes_created.push( response );
                                      $scope.nb_cahiers_de_textes_created += _(response).size();
                                  } );
                          }

                          // Create Salle
                          $scope.nb_expected_salles = _($scope.pronote.salles).size();

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
                                           $scope.nb_salles_created = _($scope.salles_created).size();

                                           var creneaux_filter = $scope.filter_creneau( true, $scope.selected );

                                           // Create Creneaux
                                           var creneaux_emploi_du_temps = _.chain($scope.pronote.Cours[0].Cours)
                                               .select( function( creneau ) {
                                                   if ( $scope.filtered_import ) {
                                                       return creneaux_filter( creneau );
                                                   } else {
                                                       return creneau.ready;
                                                   }
                                               } )
                                               .map( function( creneau ) {
                                                   creneau.created = [];

                                                   creneau.heure_debut = libelleHeure_to_Date( $scope.pronote.plages_horaires[ creneau.NumeroPlaceDebut ].LibelleHeureDebut );
                                                   creneau.heure_fin = moment( creneau.heure_debut ).add( parseInt( creneau.NombrePlaces ) * parseInt( $scope.pronote.GrilleHoraire[0].DureePlace ), 'minutes' ).toDate();

                                                   // Aujourd'hui: 1 créneau = 1 enseignant, 1 regroupement, 1 salle, 1 matière
                                                   return _(creneau.Matiere).map( function( matiere_pronote ) {
                                                       var matiere = $scope.pronote.matieres[ matiere_pronote.Ident ].laclasse;

                                                       return _(creneau.Professeur).map( function( enseignant_pronote ) {
                                                           var enseignant_laclasse = $scope.pronote.enseignants[ enseignant_pronote.Ident ].laclasse;

                                                           return _(creneau.Salle).map( function( salle_pronote ) {
                                                               var salle_laclasse = _($scope.salles_created).find( { identifiant: salle_pronote.Ident } );
                                                               var creneaux_classes = _(creneau.Classe).map( function( classe_pronote ) {
                                                                   return { jour_de_la_semaine: parseInt( creneau.Jour ),
                                                                            heure_debut: creneau.heure_debut,
                                                                            heure_fin: creneau.heure_fin,
                                                                            matiere_id: matiere.id,
                                                                            regroupement_id: $scope.pronote.classes[ classe_pronote.Ident ].laclasse.id,
                                                                            semaines_de_presence_regroupement: parseInt( classe_pronote.Semaines ),
                                                                            salle_id: salle_laclasse.id,
                                                                            semaines_de_presence_salle: parseInt( salle_pronote.Semaines ),
                                                                            enseignant_id: enseignant_laclasse.ent_id,
                                                                            semaines_de_presence_enseignant: parseInt( enseignant_pronote.Semaines ) };
                                                               } );
                                                               var creneaux_groupes = _(creneau.Groupe).map( function( groupe_pronote ) {
                                                                   return { jour_de_la_semaine: parseInt( creneau.Jour ),
                                                                            heure_debut: creneau.heure_debut,
                                                                            heure_fin: creneau.heure_fin,
                                                                            matiere_id: matiere.id,
                                                                            regroupement_id: $scope.pronote.groupes_eleves[ groupe_pronote.Ident ].laclasse.id,
                                                                            semaines_de_presence_regroupement: parseInt( groupe_pronote.Semaines ),
                                                                            salle_id: salle_laclasse.id,
                                                                            semaines_de_presence_salle: parseInt( salle_pronote.Semaines ),
                                                                            enseignant_id: enseignant_laclasse.ent_id,
                                                                            semaines_de_presence_enseignant: parseInt( enseignant_pronote.Semaines ) };
                                                               } );
                                                               return [ creneaux_classes, creneaux_groupes ];
                                                           } );
                                                       } );
                                                   } );
                                               } )
                                               .flatten()
                                               .value();

                                           $scope.creneaux_created = [];
                                           $scope.nb_creneaux_created = 0;

                                           while ( creneaux_emploi_du_temps.length > 0 ) {
                                               CreneauxEmploiDuTemps.bulk( {
                                                   uai: $scope.pronote.UAI,
                                                   creneaux_emploi_du_temps: creneaux_emploi_du_temps.splice( 0, bulk_package_size )
                                               } ).$promise
                                                   .then( function( response ) {
                                                       $scope.creneaux_created.push( response );
                                                       $scope.nb_creneaux_created += _(response).size();
                                                   } );
                                           }
                                       } );

                          $scope.processing = false;
                      };
                  } ] );
