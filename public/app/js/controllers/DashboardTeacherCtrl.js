'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller( 'DashboardTeacherCtrl',
                 [ '$scope', '$stateParams', '$q', '$locale', '$timeout', 'moment', 'toastr',
                   'API', 'Cours', 'Annuaire', 'current_user', 'PIECHART_DEFINITION', 'MULTIBARCHART_DEFINITION',
                   function ( $scope, $stateParams, $q, $locale, $timeout, moment, toastr,
                              API, Cours, Annuaire, current_user, PIECHART_DEFINITION, MULTIBARCHART_DEFINITION ) {
                       $scope.mois = _($locale.DATETIME_FORMATS.MONTH).toArray();
                       $scope.scope = $scope;
                       $scope.moisCourant = null;
                       $scope.montre_valides = current_user.profil_actif.type !== 'DIR';
                       $scope.nb_saisies_visables = 0;
                       $scope.current_user = current_user;
                       $scope.enseignant_id = _($stateParams).has( 'enseignant_id' ) ? $stateParams.enseignant_id : $scope.current_user.id;

                       var calc_nb_saisies_visables = function( saisies ) {
                           return _(saisies).select( { recent: false, valide: false } ).length;
                       };

                       $scope.detail_regroupement = function( group_id ) {
                           _($scope.enseignant.liste_regroupements).findWhere({ id: group_id });
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
                                                 $scope.graphiques.multiBarChart.data = [ { key: 'saisies non visées',
                                                                                            values: [] },
                                                                                          { key: 'saisies visées',
                                                                                            values: [] } ];
                                                 $scope.graphiques.pieChart.data = [ { label: 'saisies non visées',
                                                                                       value: 0 },
                                                                                     { label: 'saisies visées',
                                                                                       value: 0 } ];

                                                 _.chain( data )
                                                     .groupBy( 'regroupement_id' )
                                                     .each( function ( regroupement ) {
                                                         var filled = regroupement.length;
                                                         var validated = _( regroupement ).where( { valide: true } ).length;
                                                         var nom_regroupement = regroupement[ 0 ].group.name;

                                                         $scope.graphiques.multiBarChart.data[0].values.push( { key: nom_regroupement,
                                                                                                                x: nom_regroupement,
                                                                                                                y: filled - validated } );
                                                         $scope.graphiques.multiBarChart.data[1].values.push( { key: nom_regroupement,
                                                                                                                x: nom_regroupement,
                                                                                                                y: validated } );

                                                         $scope.graphiques.pieChart.data[ 0 ].value += filled - validated;
                                                         $scope.graphiques.pieChart.data[ 1 ].value += validated;
                                                     } );
                                             }
                                           };

                       $scope.select_all_regroupements = function() {
                           $scope.selected_regroupements = $scope.enseignant.liste_regroupements;
                           $scope.graphiques.populate( $scope.raw_data );
                       };

                       $scope.select_no_regroupements = function() {
                           $scope.selected_regroupements = [];
                           $scope.graphiques.populate( $scope.raw_data );
                       };

                       $scope.valide = function( saisie ) {
                           if ( current_user.profil_actif.type === 'DIR' ) {
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
                                   cancelButtonText: 'Annuler' } )
                               .then( function confirm() {
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
                               },
                                      function cancel() {} );
                       };

                       // Récupération et consommation des données
                       Annuaire.get_user( $scope.enseignant_id )
                           .then( function ( response ) {
                               $scope.enseignant = response.data;

                               $scope.enseignant.get_actual_groups()
                                   .then( function( response ) {
                                       $scope.enseignant.liste_regroupements = _.chain(response)
                                           .select( function( group ) {
                                               return group.type !== 'GPL'
                                                   && group.structure_id === $scope.current_user.profil_actif.structure_id;
                                           } )
                                           .uniq( function( group ) { return group.id; } )
                                           .compact()
                                           .value();

                                       $scope.enseignant.prof_principal = _.chain($scope.enseignant.groups)
                                           .where({ type: 'PRI' })
                                           .pluck('group_id')
                                           .map( function( group_id ) {
                                               return _($scope.enseignant.liste_regroupements).findWhere({ id: group_id });
                                           } )
                                           .value();

                                       $scope.select_all_regroupements();
                                   } );

                               $scope.enseignant.get_actual_subjects()
                                   .then( function( response ) {
                                       $scope.enseignant.liste_matieres = _.chain(response)
                                           .uniq( function( subject ) { return subject.id; } )
                                           .compact()
                                           .value();
                                   } );

                               return API.get_enseignant( { enseignant_id: $scope.enseignant_id,
                                                            uai: $scope.current_user.profil_actif.structure_id } ).$promise;
                           } )
                           .then( function success( response ) {
                               var _2_semaines_avant = moment().subtract( 2, 'weeks' );

                               $scope.raw_data = _(response.saisies).map( function ( saisie, index ) {
                                   // on référence l'index d'origine dans chaque élément pour propager la validation
                                   saisie.index = index;
                                   saisie.cours = new Cours( saisie.cours );
                                   saisie.regroupement_id = parseInt( saisie.regroupement_id );
                                   saisie.month = moment( saisie.cours.date_cours ).month();
                                   saisie.recent = moment( saisie.cours.date_cours ).isAfter( _2_semaines_avant );

                                   saisie.matiere = _($scope.enseignant.liste_matieres).findWhere({ id: saisie.matiere_id });
                                   if ( _(saisie.matiere).isUndefined() ) {
                                       saisie.matiere = Annuaire.get_subject( saisie.matiere_id );
                                   }
                                   saisie.group = _($scope.enseignant.liste_regroupements).findWhere({ id: saisie.regroupement_id });
                                   if ( _(saisie.group).isUndefined() ) {
                                       Annuaire.get_group( saisie.regroupement_id )
                                           .then( function success( response ) {
                                               saisie.group = response.data;
                                           } );
                                   }

                                   return saisie;
                               } );

                               $scope.graphiques.populate( $scope.raw_data );
                               $scope.nb_saisies_visables = calc_nb_saisies_visables( $scope.raw_data );
                           } );
                   } ] );
