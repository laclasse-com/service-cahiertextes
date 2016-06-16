'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller('ImportCtrl',
                [ '$scope', '$http', '$locale', 'toastr', 'APP_PATH', 'Annuaire', 'fileUpload',
                  'Etablissements', 'PlagesHoraires', 'Salles', 'CreneauxEmploiDuTemps', 'CahiersDeTextes',
                  'current_user',
                  function ( $scope, $http, $locale, toastr, APP_PATH, Annuaire, fileUpload,
                             Etablissements, PlagesHoraires, Salles, CreneauxEmploiDuTemps, CahiersDeTextes,
                             current_user ) {
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

                      Annuaire.get_matieres()
                          .then( function( response ) {
                              $scope.matieres = response.data;

                              _($scope.matieres).each( function( matiere ) {
                                  matiere.libelle_long = matiere.libelle_long.toUpperCase();
                                  matiere.displayed_label = matiere.libelle_long;
                              } );
                          } );

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
                          $scope.pronote = false;
                          $scope.loading_file = true;

                          fileUpload.uploadFileToUrl( fichier, APP_PATH + '/api/v1/import/pronote/decrypt' )
                              .success( function( data, status, headers, config ) {
                                  // 1. Récupérer le fichier Pronote décrypté
                                  $scope.pronote = data;
                                  $scope.pronote.GrilleHoraire[0].DureePlace = parseInt( $scope.pronote.GrilleHoraire[0].DureePlace );

                                  Annuaire.get_etablissement( $scope.pronote.UAI )
                                      .then( function( response ) {
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

                                          // 2. Récupérer toutes les infos de l'établissement et toutes les matières
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

                                          _($scope.pronote.Groupes[0].Groupe)
                                              .each( function( regroupement ) {
                                                  regroupement.displayed_label = regroupement.Nom;
                                                  regroupement.laclasse = _($scope.etablissement.groupes_eleves).findWhere( { libelle_aaf: regroupement.Nom.toUpperCase() } );
                                                  regroupement.edit = _(regroupement.laclasse).isUndefined();
                                                  if ( !regroupement.edit ) {
                                                      regroupement.laclasse.displayed_label = regroupement.laclasse.libelle_aaf;
                                                  }
                                              } );

                                          $scope.pronote.matieres = groupByKey( $scope.pronote.Matieres[0].Matiere, 'Ident' );
                                          $scope.pronote.enseignants = groupByKey( $scope.pronote.Professeurs[0].Professeur, 'Ident' );
                                          $scope.pronote.classes = groupByKey( $scope.pronote.Classes[0].Classe, 'Ident' );
                                          $scope.pronote.salles = groupByKey( $scope.pronote.Salles[0].Salle, 'Ident' );
                                          $scope.pronote.plages_horaires = groupByKey( $scope.pronote.GrilleHoraire[0].PlacesParJour[0].Place, 'Numero' );
                                          $scope.pronote.groupes_eleves = groupByKey( $scope.pronote.Groupes[0].Groupe, 'Ident' );

                                          $scope.matcheable_data.push( { title: 'Matières',
                                                                         pronote: $scope.pronote.matieres,
                                                                         annuaire: $scope.matieres } );
                                          $scope.matcheable_data.push( { title: 'Enseignants',
                                                                         pronote: $scope.pronote.enseignants,
                                                                         annuaire: $scope.etablissement.teachers } );
                                          $scope.matcheable_data.push( { title: 'Classes',
                                                                         pronote: $scope.pronote.classes,
                                                                         annuaire: $scope.etablissement.classes } );
                                          $scope.matcheable_data.push( { title: 'Groupes d\'élèves',
                                                                         pronote: $scope.pronote.groupes_eleves,
                                                                         annuaire: $scope.etablissement.groupes_eleves } );

                                          $scope.score_creneaux_update_counters(  );

                                          $scope.loading_file = false;
                                      } );
                              } );
                      };

                      $scope.score_creneaux_update_counters = function(  ) {
                          _($scope.pronote.Cours[0].Cours).each( function( creneau ) {
                              creneau.readiness = { matiere: !_($scope.pronote.matieres[ creneau.Matiere[0].Ident ].laclasse).isUndefined(),
                                                    enseignant: _(creneau.Professeur).reduce( function( memo, enseignant ) { return memo && !_($scope.pronote.enseignants[ enseignant.Ident ].laclasse).isUndefined(); }, true ),
                                                    classe: _(creneau.Classe).reduce( function( memo, classe ) { return memo && !_($scope.pronote.classes[ classe.Ident ].laclasse).isUndefined(); }, true ),
                                                    groupe_eleve: _(creneau.Groupe).reduce( function( memo, groupe ) { return memo && !_($scope.pronote.groupes_eleves[ groupe.Ident ].laclasse).isUndefined(); }, true ) };

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

                                           // Create Creneaux
                                           var creneaux_emploi_du_temps = _.chain($scope.pronote.Cours[0].Cours)
                                               .select( function( creneau ) { return creneau.ready; } )
                                               .map( function( creneau ) {
                                                   creneau.created = [];

                                                   creneau.heure_debut = libelleHeure_to_Date( $scope.pronote.plages_horaires[ creneau.NumeroPlaceDebut ].LibelleHeureDebut );
                                                   creneau.heure_fin = creneau.heure_debut;
                                                   creneau.heure_fin.setMinutes( creneau.heure_fin.getMinutes() + parseInt( $scope.pronote.GrilleHoraire[0].DureePlace ) );

                                                   // Aujourd'hui: 1 créneau = 1 enseignant, 1 regroupement, 1 salle, 1 matière
                                                   return _(creneau.Matiere).map( function( matiere_pronote ) {
                                                       var matiere = $scope.pronote.matieres[ matiere_pronote.Ident ].laclasse;

                                                       return _(creneau.Professeur).map( function( enseignant_pronote ) {
                                                           var enseignant_laclasse = $scope.pronote.enseignants[ enseignant_pronote.Ident ].laclasse;

                                                           return _(creneau.Salle).map( function( salle_pronote ) {
                                                               var salle_laclasse = _($scope.salles_created).find( { identifiant: salle_pronote.Ident } );
                                                               if ( _(salle_laclasse).isUndefined() ) { return []; };

                                                               return [
                                                                   _(creneau.Classe).map( function( classe_pronote ) {
                                                                       var classe_laclasse = $scope.pronote.classes[ classe_pronote.Ident ].laclasse;
                                                                       return {
                                                                           jour_de_la_semaine: parseInt( creneau.Jour ),
                                                                           heure_debut: creneau.heure_debut,
                                                                           heure_fin: creneau.heure_fin,
                                                                           matiere_id: matiere.id,
                                                                           regroupement_id: classe_laclasse.id,
                                                                           semaines_de_presence_regroupement: classe_pronote.Semaines,
                                                                           salle_id: salle_laclasse.id,
                                                                           semaines_de_presence_salle: salle_pronote.Semaines,
                                                                           enseignant_id: enseignant_laclasse.ent_id,
                                                                           semaines_de_presence_enseignant: enseignant_pronote.Semaines
                                                                       };
                                                                   } ),

                                                                   _(creneau.Groupe).map( function( groupe_pronote ) {
                                                                       var groupe_laclasse = $scope.pronote.groupes_eleves[ groupe_pronote.Ident ].laclasse;
                                                                       return {
                                                                           jour_de_la_semaine: parseInt( creneau.Jour ),
                                                                           heure_debut: creneau.heure_debut,
                                                                           heure_fin: creneau.heure_fin,
                                                                           matiere_id: matiere.id,
                                                                           regroupement_id: groupe_laclasse.id,
                                                                           semaines_de_presence_regroupement: groupe_pronote.Semaines,
                                                                           salle_id: salle_laclasse.id,
                                                                           semaines_de_presence_salle: salle_pronote.Semaines,
                                                                           enseignant_id: enseignant_laclasse.ent_id,
                                                                           semaines_de_presence_enseignant: enseignant_pronote.Semaines
                                                                       };
                                                                   } )
                                                               ];
                                                           } );
                                                       } );
                                                   } );
                                               } )
                                               .flatten()
                                               .value();

                                           $scope.creneaux_created = [];
                                           $scope.nb_creneaux_created = 0;

                                           while ( creneaux_emploi_du_temps.length > 0 ) {
                                               var slice_of_creneaux_emploi_du_temps = creneaux_emploi_du_temps.splice( 0, bulk_package_size );
                                               CreneauxEmploiDuTemps.bulk( {
                                                   uai: $scope.pronote.UAI,
                                                   creneaux_emploi_du_temps: slice_of_creneaux_emploi_du_temps
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
