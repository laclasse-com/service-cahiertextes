'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller( 'StatsEnseignantCtrl',
                 [ '$scope', '$stateParams', '$q', '$locale', '$timeout', 'moment', 'toastr',
                   'API', 'Cours', 'Annuaire', 'current_user', 'PIECHART_DEFINITION', 'MULTIBARCHART_DEFINITION',
                   function ( $scope, $stateParams, $q, $locale, $timeout, moment, toastr,
                              API, Cours, Annuaire, current_user, PIECHART_DEFINITION, MULTIBARCHART_DEFINITION ) {
                       $scope.mois = _($locale.DATETIME_FORMATS.MONTH).toArray();
                       $scope.scope = $scope;
                       $scope.moisCourant = null;
                       $scope.montre_valides = current_user.profil_actif.profil_id !== 'DIR';
                       $scope.nb_saisies_visables = 0;
                       $scope.current_user = current_user;
                       $scope.enseignant_id = _($stateParams).has( 'enseignant_id' ) ? $stateParams.enseignant_id : $scope.current_user.uid;

                       var calc_nb_saisies_visables = function( saisies ) {
                           return _(saisies).select( { recent: false, valide: false } ).length;
                       };

                       $scope.detail_regroupement = function( id ) {
                           return Annuaire.get_regroupement( parseInt( id ) )
                           // .$promise.then( function( response ) {
                           //     delete response.etablissement;
                           //     delete response.niveau;
                           //     delete response.profs;
                           //     delete response.eleves;

                           //     return response;
                           // } );
                       };

                       $scope.filter_saisie = function( montre_valides, mois, selected_regroupements ) {
                           return function( saisie ) {
                               return ( montre_valides || _(saisie.cours.date_validation).isNull() )
                                   && ( _(mois).isNull() || saisie.mois == mois )
                                   && ( _.chain(selected_regroupements).pluck('id').contains( saisie.regroupement_id ).value() );
                           };
                       };

                       // Graphiques
                       $scope.graphiques = { pieChart: angular.copy( PIECHART_DEFINITION ),
                                             multiBarChart: angular.copy( MULTIBARCHART_DEFINITION ),
                                             populate: function ( data ) {
                                                 $scope.graphiques.multiBarChart.data = [ { key: 'saisies',
                                                                                            values: [] },
                                                                                          { key: 'visas',
                                                                                            values: [] }];
                                                 $scope.graphiques.pieChart.data = [ { label: 'saisies',
                                                                                       value: 0 },
                                                                                     { label: 'visas',
                                                                                       value: 0 } ];

                                                 _.chain( data )
                                                     .groupBy( 'regroupement_id' )
                                                     .each( function ( regroupement ) {
                                                         var filled = regroupement.length;
                                                         var validated = _( regroupement ).where( { valide: true } ).length;
                                                         var nom_regroupement = $scope.detail_regroupement( regroupement[ 0 ].regroupement_id ).libelle;

                                                         $scope.graphiques.multiBarChart.data[0].values.push( { key: nom_regroupement,
                                                                                                                x: nom_regroupement,
                                                                                                                y: filled } );
                                                         $scope.graphiques.multiBarChart.data[1].values.push( { key: nom_regroupement,
                                                                                                                x: nom_regroupement,
                                                                                                                y: validated } );

                                                         $scope.graphiques.pieChart.data[ 0 ].value += filled - validated;
                                                         $scope.graphiques.pieChart.data[ 1 ].value += validated;
                                                     } );
                                             }
                                           };

                       $scope.select_all_regroupements = function() {
                           $scope.selected_regroupements = $scope.classes;
                           $scope.graphiques.populate( $scope.raw_data );
                       };

                       $scope.select_no_regroupements = function() {
                           $scope.selected_regroupements = [];
                           $scope.graphiques.populate( $scope.raw_data );
                       };

                       $scope.valide = function( saisie ) {
                           if ( current_user.profil_actif.profil_id === 'DIR' ) {
                               var disable_toastr = _(saisie).has( 'disable_toastr' );
                               saisie.cours.$valide().then( function( response ) {
                                   saisie.valide = !_(response.date_validation).isNull();

                                   if ( !$scope.montre_valides && !_(response.date_validation).isNull() ) {
                                       var date_validation_holder = response.date_validation;
                                       response.date_validation = null;

                                       $timeout( function() { response.date_validation = date_validation_holder; }, 3000 );
                                   }

                                   $scope.nb_saisies_visables = calc_nb_saisies_visables( $scope.raw_data );
                                   $scope.graphiques.populate( $scope.raw_data );

                                   if ( !disable_toastr ) {
                                       toastr.success( 'Séquence pédagogique ' + (saisie.valide ? '' : 'dé-') + 'visée.',
                                                       'Opération réussie' );
                                   }
                               } );
                           }
                       };

                       $scope.valide_all = function() {
                           swal( { title: 'Tout viser ?',
                                   text: 'Cette action va viser toutes les saisies actuellement affichées à l\'écran.',
                                   type: 'warning',
                                   showCancelButton: true,
                                   confirmButtonColor: '#ff6b55',
                                   confirmButtonText: 'Confirmer',
                                   cancelButtonText: 'Annuler' },
                                 function () {
                                     var counter = 0;
                                     _.chain($scope.raw_data)
                                         .reject( function( saisie ) { return saisie.valide || saisie.recent; } )
                                         .each( function( saisie ) {
                                             saisie.disable_toastr = true;
                                             $scope.valide( saisie );
                                             counter++;
                                         } );

                                     if ( counter > 0 ) {
                                         var pluriel = counter > 1 ? 's' : '';
                                         var message = counter + ' séquence' + pluriel + ' pédagogique' + pluriel + ' visée' + pluriel + '.';
                                         toastr.success( message, 'Opération réussie' );
                                     }
                                 } );
                       };

                       // Récupération et consommation des données
                       Annuaire.get_user( $scope.enseignant_id )
                           .$promise.then(
                               function ( response ) {
                                   $scope.enseignant = response;

                                   $scope.enseignant.email_principal = _($scope.enseignant.emails).find( { principal: true } );
                                   if ( _($scope.enseignant.email_principal).isUndefined() ) {
                                       $scope.enseignant.email_principal = _($scope.enseignant.emails).find( { type: 'Ent' } );
                                   }
                                   if ( _($scope.enseignant.email_principal).isUndefined() ) {
                                       $scope.enseignant.email_principal = _($scope.enseignant.emails).first();
                                   }

                                   // filtrer les classes de l'enseignant sur l'établissement actif
                                   $scope.enseignant.liste_classes = _.chain( $scope.enseignant.classes )
                                       .reject( function( classe ) {
                                           return classe.etablissement_code != $scope.current_user.profil_actif.etablissement_code_uai;
                                       } )
                                       .uniq( function ( classe ) {
                                           return classe.classe_id;
                                       } )
                                       .compact()
                                       .value();

                                   $scope.enseignant.liste_matieres = _.chain( $scope.enseignant.classes ).pluck('matiere_libelle').uniq().compact().value();

                                   $scope.enseignant.prof_principal = _.chain( $scope.enseignant.classes )
                                       .filter( function ( matiere ) { return matiere.prof_principal == 'O'; } )
                                       .pluck( 'classe_libelle' )
                                       .uniq()
                                       .compact()
                                       .value();

                                   API.get_enseignant( { enseignant_id: $scope.enseignant_id,
                                                         uai: $scope.current_user.profil_actif.etablissement_code_uai } )
                                       .$promise.then( function success( response ) {
                                           var _2_semaines_avant = moment().subtract( 2, 'weeks' );

                                           $scope.raw_data = _(response.saisies).map( function ( saisie, index ) {
                                               // on référence l'index d'origine dans chaque élément pour propager la validation
                                               saisie.index = index;
                                               saisie.cours = new Cours( saisie.cours );
                                               saisie.regroupement_id = parseInt( saisie.regroupement_id );
                                               saisie.month = moment( saisie.cours.date_cours ).month();
                                               saisie.recent = moment( saisie.cours.date_cours ).isAfter( _2_semaines_avant );

                                               return saisie;
                                           } );

                                           $scope.matieres = _.chain( $scope.raw_data)
                                               .pluck('matiere_id')
                                               .map( function( matiere_id ) {
                                                   var matiere = _($scope.current_user.profil_actif.matieres).findWhere({ id: matiere_id });
                                                   if ( _(matiere).isUndefined() ) {
                                                       matiere = Annuaire.get_matiere( matiere_id );
                                                   }

                                                   return [ matiere_id, matiere ];
                                               } )
                                               .object()
                                               .value();

                                           var promesses_classes = _.chain( $scope.raw_data)
                                               .pluck('regroupement_id')
                                               .uniq()
                                               .map( function( regroupement_id ) {
                                                   return $scope.detail_regroupement( regroupement_id );
                                               } )
                                               .value();

                                           $scope.nb_saisies_visables = calc_nb_saisies_visables( $scope.raw_data );

                                           $q.all( promesses_classes ).then( function( response ) {
                                               $scope.classes = response;
                                               $scope.select_all_regroupements();
                                           } );
                                       } );
                               } );
                   } ] );
