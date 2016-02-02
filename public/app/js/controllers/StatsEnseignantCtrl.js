'use strict';

angular.module( 'cahierDeTextesClientApp' )
    .controller( 'StatsEnseignantCtrl',
                 [ '$scope', '$stateParams', '$q', '$locale', '$timeout', 'API', 'Cours', 'Annuaire', 'current_user', 'PIECHART_DEFINITION', 'BARCHART_DEFINITION',
                   function ( $scope, $stateParams, $q, $locale, $timeout, API, Cours, Annuaire, current_user, PIECHART_DEFINITION, BARCHART_DEFINITION ) {
                       $scope.mois = _($locale.DATETIME_FORMATS.MONTH).toArray();
                       $scope.scope = $scope;
                       $scope.classe = null;
                       $scope.moisCourant = null;
                       $scope.matieres = {};
                       $scope.classes = {};
                       $scope.montre_valides = false;

                       var filtre_saisies = function ( saisies, mois, classe ) {
                           var data = saisies;
                           if ( $scope.current_user[ 'profil_actif' ][ 'profil_id' ] === 'DIR' ) {
                               var _2_semaines_avant = moment().subtract( 2, 'weeks' );
                               data = _( data ).select( function( saisie ) {
                                   return moment( saisie.cours.date_cours ).isBefore( _2_semaines_avant );
                               } );
                           }
                           if ( mois != null ) {
                               data = _( data ).where( { month: mois } );
                           }
                           if ( classe != null ) {
                               data = _( data ).where( { regroupement_id: classe.id } );
                           }
                           return data;
                       };

                       $scope.valide = function( saisie ) {
                           saisie.cours.$valide().then( function( response ) {
                               if ( !$scope.montre_valides && !_(response.date_validation).isNull() ) {
                                   var date_validation_holder = response.date_validation;
                                   response.date_validation = null;

                                   $timeout( function() { response.date_validation = date_validation_holder; }, 3000 );
                               }
                           } );
                       };

                       $scope.valide_all = function() {
                           swal({ title: 'Tout valider ?',
                                  text: 'Cette action va valider toutes les saisies actuellement affichées à l\'écran.',
                                  type: 'warning',
                                  showCancelButton: true,
                                  confirmButtonColor: '#ff6b55',
                                  confirmButtonText: 'Confirmer',
                                  cancelButtonText: 'Annuler' },
                                function () {
                                    var _2_jours_avant = moment().subtract( 2, 'days' );
                                    _.chain($scope.raw_data)
                                        .reject( function( saisie ) {
                                            return saisie.valide || moment( saisie.cours.date_cours ).isAfter( _2_jours_avant );
                                        } )
                                        .each( function( saisie ) {
                                            $scope.valide( saisie );
                                        } );
                                });
                       };

                       // Graphiques
                       $scope.graphiques = {
                           pieChart: PIECHART_DEFINITION(),
                           barChart: BARCHART_DEFINITION(),
                           populate: function ( data ) {
                               $scope.graphiques.barChart.data = [];
                               $scope.graphiques.pieChart.data = [ {
                                   label: 'visas',
                                   value: 0
                               }, {
                                   label: 'saisies',
                                   value: 0
                               } ];

                               var saisies = {
                                   key: "saisies",
                                   values: []
                               };
                               var valides = {
                                   key: "visas",
                                   values: []
                               };

                               _.chain( filtre_saisies( data, $scope.moisCourant, $scope.classe ) )
                                   .groupBy( 'regroupement_id' )
                                   .each( function ( classe ) {
                                       var filled = classe.length;
                                       var validated = _( classe ).where( {
                                           valide: true
                                       } ).length;

                                       saisies.values.push( [ $scope.classes[ classe[ 0 ].regroupement_id ].libelle, filled ] );
                                       valides.values.push( [ $scope.classes[ classe[ 0 ].regroupement_id ].libelle, validated ] );

                                       $scope.graphiques.barChart.data = [ valides, saisies ];

                                       $scope.graphiques.pieChart.data[ 0 ].value += validated;
                                       $scope.graphiques.pieChart.data[ 1 ].value += filled - validated;
                                   } );
                           }
                       };

                       $scope.process_data = function () {
                           if ( $scope.raw_data !== undefined ) {
                               var _2_jours_avant = moment().subtract( 2, 'days' );
                               $scope.raw_data = _( $scope.raw_data )
                                   .map( function ( saisie, index ) {
                                       // on référence l'index d'origine dans chaque élément pour propager la validation
                                       saisie.index = index;
                                       saisie.cours = new Cours( saisie.cours );
                                       saisie.regroupement_id = parseInt( saisie.regroupement_id );
                                       saisie.month = moment( saisie.cours.date_cours ).month();
                                       saisie.recent = moment( saisie.cours.date_cours ).isAfter( _2_jours_avant );
                                       // saisie.devoir = new Devoirs( saisie.devoir );
                                       return saisie;
                                   } );

                               // consommation des données par les graphiques
                               $scope.graphiques.populate( $scope.raw_data );
                           }
                       };

                       $scope.current_user = current_user;
                       $scope.enseignant_id = $stateParams.enseignant_id;
                       if ( $scope.enseignant_id === undefined && $scope.enseignant_id != $scope.current_user.uid ) {
                           $scope.enseignant_id = $scope.current_user.uid;
                       }

                       // Récupération et consommation des données
                       Annuaire.get_user( $scope.enseignant_id )
                           .$promise.then(
                               function ( response ) {
                                   $scope.enseignant = response;
                                   // filtrer les classes de l'enseignant sur l'établissement actif
                                   $scope.enseignant.liste_classes = _.chain( $scope.enseignant.classes )
                                       .reject( function( classe ) {
                                           return classe.etablissement_code != $scope.current_user.profil_actif.etablissement_code_uai;
                                       } )
                                       .uniq( function ( classe ) {
                                           return classe.classe_id;
                                       } )
                                       .value();

                                   $scope.enseignant.liste_matieres = _.chain( $scope.enseignant.classes ).pluck('matiere_libelle').uniq().value();

                                   $scope.enseignant.prof_principal = _.chain( $scope.enseignant.classes )
                                       .filter( function ( matiere ) {
                                           return matiere.prof_principal == 'O';
                                       } )
                                       .map( function ( matiere ) {
                                           return matiere.classe_libelle;
                                       } )
                                       .value();
                               } );

                       API.get_enseignant( {
                           enseignant_id: $scope.enseignant_id,
                           uai: $scope.current_user[ 'profil_actif' ][ 'uai' ]
                       } )
                           .$promise.then(
                               function success( response ) {
                                   var extract = function( saisies, id_name, traitement ) {
                                       return _.chain( saisies )
                                           .flatten()
                                           .pluck( id_name )
                                           .uniq()
                                           .compact()
                                           .reject( function( item_id ) { return item_id === 'undefined'; } )
                                           .map( function( item_id ) { return traitement( item_id ); } )
                                           .object()
                                           .value();
                                   };

                                   $scope.raw_data = response.saisies;
                                   $scope.matieres = extract( $scope.raw_data, 'matiere_id',
                                                              function( matiere_id ) {
                                                                  return [ matiere_id, Annuaire.get_matiere( matiere_id ) ];
                                                              } );

                                   $scope.classes = extract( $scope.raw_data, 'regroupement_id',
                                                             function( regroupement_id ) {
                                                                 return [ regroupement_id, Annuaire.get_regroupement( regroupement_id ) ];
                                                             } );
                                   $q.all( $scope.classes ).then( function() {
                                       $scope.process_data();
                                   } );
                               } );

                       angular.element('#ui-view-content').after( current_user.marqueur_xiti );
                   } ] );
