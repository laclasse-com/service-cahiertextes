'use strict';

angular.module( 'cahierDeTexteApp' )
    .controller( 'PopupEditionCtrl',
		 [ '$scope', '$filter', '$q', '$sce', '$modalInstance', 'APP_PATH', 'DOCS_URL', 'SEMAINES_TOUTES_ACTIVES', 'Documents', 'API', 'CreneauEmploiDuTemps', 'Cours', 'Devoirs', 'User', 'cours', 'devoirs', 'creneau', 'raw_data', 'classes', 'matieres',
		   function ( $scope, $filter, $q, $sce, $modalInstance, APP_PATH, DOCS_URL, SEMAINES_TOUTES_ACTIVES, Documents, API, CreneauEmploiDuTemps, Cours, Devoirs, User, cours, devoirs, creneau, raw_data, classes, matieres ) {
		       $scope.app_path = APP_PATH;
		       $scope.DOCS_URL_login = $sce.trustAsResourceUrl( DOCS_URL + '/login' );
		       $scope.faulty_docs_app = false;

		       $scope.erreurs = [];
		       $scope.dirty = false;
		       $scope.deleted = false;
		       $scope.mode_duplication = false;

		       // http://stackoverflow.com/questions/19408883/angularjs-select-not-2-way-binding-to-model
		       $scope.scope = $scope;
		       //  ^ ^ Cette ligne est peut-être inutile ?

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
			   $scope.matieres = matieres;

			   $scope.creneau = creneau;
			   $scope.creneau.en_creation = _($scope.creneau.matiere_id).isEmpty() || $scope.creneau.regroupement_id === 'undefined';
			   $scope.creneau.etranger = !$scope.creneau.en_creation && !_.chain( $scope.creneau.enseignants ).pluck( 'enseignant_id' ).include( $scope.current_user.uid ).value();
			   $scope.creneau.previous_regroupement_id = $scope.creneau.regroupement_id;
			   if ( _(creneau.vierge).isUndefined() ) {
			       creneau.vierge = true;
			   }
			   if ( $scope.creneau.en_creation ) {
			       $scope.creneau.tmp_heure_debut = $filter( 'correctTimeZoneToGMT' )( $scope.creneau.heure_debut );
			       $scope.creneau.tmp_heure_fin = $filter( 'correctTimeZoneToGMT' )( $scope.creneau.heure_fin );
			       $scope.classe = _( $scope.classes ).first();
			       $scope.matiere = _( $scope.matieres ).first();
			   } else {
			       $scope.creneau.tmp_heure_debut = angular.copy( $scope.creneau.heure_debut );
			       $scope.creneau.tmp_heure_fin = angular.copy( $scope.creneau.heure_fin );
			       $scope.classe = _( $scope.classes ).findWhere( { id: parseInt( $scope.creneau.regroupement_id ) } );
			       $scope.matiere = _($scope.matieres).findWhere( { id: $scope.creneau.matiere_id } );
			   }
			   $scope.creneau.n_week = moment($scope.creneau.tmp_heure_debut).week();

			   // Gestion des semaines actives
			   var fixnum_to_bitfield = function( fixnum ) {
			       var string = fixnum.toString(2);
			       var padding = '';
			       _(53 - string.length).times( function() { padding += '0'; } );
			       string = padding + string;
			       return _(string.split('')
					.map( function( e ) { return parseInt( e ); } )
					.reverse())
				   .rest();
			   };
			   var bitfield_to_fixnum = function( bitfield ) {
			       return parseInt( bitfield.reverse().join('') + '0', 2 );
			   };
			   $scope.semaines_actives = { regroupement: [] };
			   $scope.apply_template = function( template_name ) {
			       // TODO: Gestion des vacances scolaires
			       var template = [];
			       switch( template_name ) {
			       case 'tout':
				   $scope.semaines_actives.regroupement = fixnum_to_bitfield( SEMAINES_TOUTES_ACTIVES );
				   break;
			       case 'rien':
				   _(52).times( function() {
				       template.push( 0 );
				   });
				   $scope.semaines_actives.regroupement = template;
				   break;
			       case 'paires':
				   _(26).times( function() {
				       template.push( 0 );
				       template.push( 1 );
				   });
				   $scope.semaines_actives.regroupement = template;
				   break;
			       case 'impaires':
				   _(26).times( function() {
				       template.push( 1 );
				       template.push( 0 );
				   });
				   $scope.semaines_actives.regroupement = template;
				   break;
			       case 'unique':
				   _(52).times( function( week ) {
				       template.push( ( week + 1 == $scope.creneau.n_week ) ? 1 : 0 );
				   });
				   $scope.semaines_actives.regroupement = template;
				   break;
			       case 'inverser':
				   $scope.semaines_actives.regroupement = _($scope.semaines_actives.regroupement).map( function( w ) {
				       return ( w == 0 ) ? 1 : 0;
				   } );
				   break;
			       case 'reinitialiser':
				   $scope.semaines_actives.regroupement = fixnum_to_bitfield( $scope.creneau.en_creation ? SEMAINES_TOUTES_ACTIVES : _(creneau.regroupements).findWhere( { regroupement_id: creneau.regroupement_id } ).semaines_de_presence );
				   break;
			       }
			   };
			   $scope.apply_template( 'reinitialiser' );

			   // helpers
			   $scope.fermer = function () {
			       $modalInstance.close( $scope );
			   };

			   $scope.effacer_creneau = function () {
			       CreneauEmploiDuTemps.delete( {
				   id: $scope.creneau.id,
				   date_creneau: $scope.creneau.heure_debut
			       } )
				   .$promise.then( function () {
				       $scope.fermer();
				   } );
			   };

			   $scope.annuler = function () {
			       if ( $scope.creneau.en_creation && _($scope.creneau.matiere_id).isEmpty() && $scope.creneau.regroupement_id === 'undefined' ) {
				   $scope.effacer_creneau();
			       } else {
				   $scope.dirty = false;
				   $scope.fermer();
			       }
			   };

			   $scope.valider = function () {
			       // réinitialisation des erreurs
			       $scope.erreurs = [];
			       var promesses = [];

			       if ( $scope.creneau.en_creation ) {
				   $scope.creneau.matiere_id = $scope.matiere.id;
				   $scope.creneau.regroupement_id = $scope.classe.id;
				   $scope.creneau.heure_debut = $filter('correctTimeZone')( $scope.creneau.tmp_heure_debut );
				   $scope.creneau.heure_fin = $filter('correctTimeZone')( $scope.creneau.tmp_heure_fin );
				   $scope.creneau.semaines_de_presence_regroupement = bitfield_to_fixnum( $scope.semaines_actives.regroupement );

				   $scope.creneau.$update();
			       } else if ( $scope.mode_duplication ) {
				   $scope.dupliquer();
			       } else {
				   // Gestion des Cours et Devoirs
				   var handle_devoirs = function( devoirs, cours ) {
				       _( devoirs ).each( function ( devoir ) {
					   if ( _( devoir ).has( 'contenu' ) && ( devoir.contenu.length > 0 ) ) {
					       // FIXME: on $save() ou $update() tous les devoirs qu'ils aient été modifiés ou non
					       var prom = $q.defer();
					       if ( devoir.create ) {
						   devoir.regroupement_id = $scope.classe.id;
						   if ( ! _(cours).isNull() ) {
						       devoir.cours_id = cours.id;
						   }
						   devoir.$save().then( function success( result ) {
						       devoir.id = result.id;
						       prom.resolve( result );
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
					   $scope.cours.regroupement_id = $scope.classe.id;
					   $scope.cours.creneau_emploi_du_temps_id = $scope.creneau.id;
					   promesse = $scope.cours.$save();
				       } else {
					   promesse = $scope.cours.$update();
				       }

				       // Devoirs liés au cours
				       if ( cours_devoirs.length > 0 ) {
					   promesse.then( function ( cours_from_DB ) {
					       handle_devoirs( cours_devoirs, cours_from_DB );
					   } );
				       }
				   }

				   // Devoirs dûs ce créneau
				   handle_devoirs( $scope.devoirs, null );
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

			       if ( _(cours).isNull() ) {
				   if ( !$scope.creneau.etranger ) {
				       $scope.cours = create_cours( creneau );
				       $scope.cours.editable = true;
				   }
			       } else {
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

				       _($scope.cours.ressources).each( function( ressource ) {
					   ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
				       } );
				       _($scope.cours.devoirs).each( function( devoir ) {
					   _(devoir.ressources).each( function( ressource ) {
					       ressource.url = $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + ressource.hash );
					   } );
				       } );

				   } );
				   $scope.cours.create = false;
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

			       var liste_créneaux_similaires = function( creneau, n_semaines_futures ) {
				   return API.get_creneaux_emploi_du_temps_similaires({ id: creneau.id,
											debut: creneau.heure_debut,
											fin: moment( creneau.heure_debut.toISOString() ).add( n_semaines_futures, 'weeks' ).toDate() } );
			       };

			       liste_créneaux_similaires( $scope.creneau, 4 )
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

				       $scope.creneaux_devoirs_possibles = _.chain(response.data)
					   .select( function( creneau ) { return creneau.regroupement_id == $scope.creneau.regroupement_id; } )
					   .map( function ( creneau ) {
					       creneau.classe = _( $scope.classes ).findWhere( { id: parseInt( creneau.regroupement_id ) } );
					       creneau.date_due = $filter( 'date' )( creneau.start, 'y-MM-dd' );
					       creneau.semaine = moment( creneau.start).from( moment( $scope.creneau.heure_debut ), true ) + ' plus tard';
					       creneau.heure_debut = new Date( creneau.heure_debut );
					       creneau.heure_fin = new Date( creneau.heure_fin );

					       return creneau;
					   } )
					   .sortBy( function ( creneau ) { // Trie par dates croissantes
					       return creneau.start;
					   } )
					   .value();
				   } );

			       // {{{ Gestion des documents attachés
			       $scope.cartable = {};
			       $scope.cartable.expandedNodes = [];
			       Documents.list_files()
				   .success( function ( response ) {
				       $scope.cartable = response;
				       $scope.cartable.files = _.chain( response.files )
					   .rest()
					   .value()
					   .map( function ( elt ) {
					       elt.children = [];
					       return elt;
					   } );
				   } )
				   .error( function() {
				       $scope.faulty_docs_app = true;
				   });

			       $scope.add_ressource = function ( item, name, hash ) {
				   if ( item.ressources === undefined ) {
				       item.ressources = [];
				   }
				   if ( _( item.ressources ).findWhere( {
				       hash: hash
				   } ) === undefined ) {
				       Documents.ajout_au_cahier_de_textes( $scope.classe, hash )
					   .success( function ( response ) {
					       item.ressources.push( {
						   name: name,
						   hash: _( response.added ).first().hash,
						   url: $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + _( response.added ).first().hash )
					       } );
					       $scope.is_dirty();
					   } );
				   }
			       };

			       $scope.upload_and_add_ressource = function ( item, fichiers ) {
				   if ( item.ressources === undefined ) {
				       item.ressources = [];
				   }
				   var responses = Documents.upload_dans_cahier_de_textes( $scope.classe, fichiers );
				   for ( var i = 0; i < responses.length; i++ ) {
				       responses[ i ]
					   .success( function ( response ) {
					       _( response.added ).each( function ( doc ) {
						   if ( _( item.ressources ).findWhere( {
						       hash: doc.hash
						   } ) === undefined ) {
						       item.ressources.push( {
							   name: doc.name,
							   hash: doc.hash,
							   url: $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + doc.hash )
						       } );
						       $scope.is_dirty();
						   }
					       } );
					   } )
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

			       $scope.treeClicked = function ( noeud ) {
				   if ( noeud.mime === 'directory' ) {
				       Documents.list_files( noeud.hash ).then( function ( response ) {
					   _.chain( response.data.files )
					       .rest()
					       .each( function ( elt ) {
						   elt.children = [];
						   noeud.children.push( elt );
					       } );
					   $scope.cartable.expandedNodes = [];
					   $scope.cartable.expandedNodes.push( _($scope.cartable.files).findWhere( noeud ) );
				       } );
				   }
			       };
			       $scope.treeOptions = {
				   dirSelectable: false
			       };
			       // }}}

			       // fonctions d'événements GUI {{{
			       $scope.ajout_devoir = function( where, creneau_cible ) {
				   if ( _(creneau_cible).isNull() ) {
				       creneau_cible = $scope.creneau;
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

			       $scope.creneau_cible_duplication_SP_updated = function() {
				   $scope.dirty = true;

				   // Calcul des créneaux cibles pour les devoirs
				   liste_créneaux_similaires( $scope.creneaux_similaires.selected, 4 )
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
			       };
			       $scope.dupliquer = function () {
				   var devoirs = angular.copy( $scope.cours.devoirs );
				   $scope.cours.$copie( {
				       regroupement_id: $scope.creneaux_similaires.selected.regroupement_id,
				       creneau_emploi_du_temps_id: $scope.creneaux_similaires.selected.creneau_emploi_du_temps_id,
				       date: $scope.creneaux_similaires.selected.start
				   } ).then( function() {
				       _(devoirs).each( function( devoir ) {
					   devoir.$copie( {
					       cours_id: $scope.cours.id,
					       creneau_emploi_du_temps_id: devoir.creneau_cible.id,
					       date_due: devoir.creneau_cible.date_due
					   } );
				       } );
				   });
			       };

			       $scope.effacer_cours = function () {
				   $scope.cours.$delete()
				       .then( function () {
					   _( $scope.devoirs ).each( function ( devoir ) {
					       devoir.$delete();
					   } );
					   $scope.deleted = true;
					   $scope.fermer();
				       } );
			       };

			       $scope.effacer_devoir_cours = function ( devoir ) {
				   if ( _(devoir).has('id') ) {
				       devoir.$delete().then( function() {
					   $scope.cours.devoirs = _( $scope.cours.devoirs )
					       .reject( function( devoir ) {
						   return devoir.deleted;
					       });
				       });
				   } else {
				       devoir.deleted = true;
				       $scope.cours.devoirs = _( $scope.cours.devoirs )
					   .reject( function( devoir ) {
					       return devoir.deleted;
					   });
				   }
			       };

			       $scope.effacer_devoir_devoirs = function ( devoir ) {
				   if ( _(devoir).has('id') ) {
				       devoir.$delete().then( function() {
					   $scope.devoirs = _( $scope.devoirs )
					       .reject( function( devoir ) {
						   return devoir.deleted;
					       });
				       });
				   } else {
				       devoir.deleted = true;
				       $scope.devoirs = _( $scope.devoirs )
					   .reject( function( devoir ) {
					       return devoir.deleted;
					   });
				   }
			       };

			       $scope.switch_to_duplication_mode = function() {
				   $scope.mode_duplication = true;
			       };

			       $scope.switch_to_creneau_edition = function() {
				   $scope.creneau.en_creation = true;
			       };
			   }	// /fin gestion des Cours et Devoirs
			   // }}}
		       } );
		   }
			       ] );
