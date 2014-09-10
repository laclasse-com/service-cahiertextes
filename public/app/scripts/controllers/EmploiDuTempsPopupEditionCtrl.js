'use strict';

angular.module( 'cahierDeTexteApp' )
    .controller( 'EmploiDuTempsPopupEditionCtrl',
		 [ '$scope', '$filter', '$q', '$sce', '$modalInstance', 'APP_PATH', 'DOCS_URL', 'SEMAINES_TOUTES_ACTIVES', 'Documents', 'API', 'CreneauEmploiDuTemps', 'Cours', 'Devoirs', 'User', 'cours', 'devoirs', 'creneau', 'raw_data', 'classes', 'matieres',
		   function ( $scope, $filter, $q, $sce, $modalInstance, APP_PATH, DOCS_URL, SEMAINES_TOUTES_ACTIVES, Documents, API, CreneauEmploiDuTemps, Cours, Devoirs, User, cours, devoirs, creneau, raw_data, classes, matieres ) {
		       $scope.app_path = APP_PATH;
		       $scope.DOCS_URL_login = $sce.trustAsResourceUrl( DOCS_URL + '/login' );
		       $scope.faulty_docs_app = false;

		       $scope.erreurs = [];
		       $scope.dirty = false;
		       $scope.accordion_cours_devoirs_open = false;
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
							enseignant_id: $scope.current_user.uid } );
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
			   $scope.creneau.etranger = !_.chain( $scope.creneau.enseignants ).pluck( 'enseignant_id' ).include( $scope.current_user.uid ).value();
			   $scope.creneau.previous_regroupement_id = $scope.creneau.regroupement_id;
			   $scope.creneau.en_creation = _($scope.creneau.matiere_id).isEmpty() || $scope.creneau.regroupement_id === 'undefined';
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

			   // Gestion des semaines actives
			   var fixnum_to_bitfield = function( fixnum ) {
			       return _(fixnum.toString(2).split('').map( function( e ) { return parseInt( e ); } )).rest();
			   };
			   var bitfield_to_fixnum = function( bitfield ) {
			       return parseInt( '1' + bitfield.join(''), 2 );
			   };
			   $scope.semaines_actives = { regroupement: [] };
			   $scope.apply_template = function( template_name ) {
			       // TODO: Gestion des vacances scolaires
			       var template = [];
			       switch( template_name ) {
			       case 'semaine_A':
				   _(26).times( function() {
				       template.push( 0 );
				       template.push( 1 );
				   });
				   $scope.semaines_actives.regroupement = template;
				   break;
			       case 'semaine_B':
				   _(26).times( function() {
				       template.push( 1 );
				       template.push( 0 );
				   });
				   $scope.semaines_actives.regroupement = template;
				   break;
			       case 'initialize':
				   $scope.semaines_actives.regroupement = fixnum_to_bitfield( $scope.creneau.en_creation ? SEMAINES_TOUTES_ACTIVES : _(creneau.regroupements).findWhere( { regroupement_id: creneau.regroupement_id } ).semaines_de_presence );
				   break;
			       }
			   };
			   $scope.apply_template( 'initialize' );

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

				       $scope.accordion_cours_devoirs_open = $scope.cours.devoirs.length > 0;

				       _(cours.devoirs).each( function( devoir ) {
					   $scope.estimation_leave( devoir );
					   devoir.tooltip = devoir.contenu;
					   if ( devoir.temps_estime > 0 ) {
					       devoir.tooltip = '<span><i class="picto temps"></i>' + devoir.temps_estime * 5 + ' minutes</span><hr>' + devoir.tooltip;
					   }
					   if ( $scope.creneau.etranger ) {
					       devoir.contenu = $sce.trustAsHtml( devoir.contenu );
					   }
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

			       $scope.creneaux_similaires = _( raw_data )
				   .filter( function ( creneau ) {
				       return ( creneau.id != $scope.creneau.id )
					   && ( creneau.matiere_id == $scope.creneau.matiere_id )
					   && ( _(creneau.cours).isNull() );
				   } )
				   .map( function ( creneau ) {
				       creneau.classe = _( $scope.classes ).findWhere( { id: parseInt( creneau.regroupement_id ) } );

				       return creneau;
				   } );
			       $scope.creneaux_similaires.selected = [];

			       //
			       // Constitution de la liste des créneaux possibles pour les dates dues des devoirs.
			       //
			       // 1. sélection des créneaux possibles en fonction du regroupement et de la matière.
			       var creneaux_devoirs_possibles = _.chain( raw_data )
				       .filter( function ( creneau ) {
					   return ( creneau.regroupement_id == $scope.classe.id )
					       && ( creneau.matiere_id == $scope.matiere.id );
				       } )
				       .map( function ( creneau ) {
					   creneau.classe = _( $scope.classes ).findWhere( { id: parseInt( creneau.regroupement_id ) } );
					   creneau.date_due = $filter( 'date' )( creneau.start, 'y-MM-dd' );
					   creneau.semaine = "cette semaine";

					   return creneau;
				       } )
				       .sortBy( function ( creneau ) { // Trie par dates croissantes
					   return creneau.start;
				       } )
				       .value();

			       // 2. on ajoute les créneaux possible sur un mois.
			       var cdp_tmp = [];
			       var nb_semaines = 4;
			       // FIXME: prendre en compte les semaines actives
			       _( nb_semaines + 1 ).times( function ( n ) {
				   _( creneaux_devoirs_possibles ).each( function ( c ) {
				       var cdp_futurs = angular.copy( c );
				       var d = new Date( cdp_futurs.start );
				       d.setDate( d.getDate() + n * 7 );
				       var f = new Date( cdp_futurs.end );
				       f.setDate( f.getDate() + n * 7 );

				       cdp_futurs.start = d.toISOString();
				       cdp_futurs.end = f.toISOString();
				       // calcul d'un attribut permettant de grouper les dates dans la selectbox
				       cdp_futurs.semaine = ( n == 0 ) ? "cette semaine" : "dans " + n + " semaine";
				       cdp_futurs.semaine += ( n > 1 ) ? "s" : "";
				       cdp_futurs.date_due = $filter( 'date' )( cdp_futurs.start, 'y-MM-dd' );

				       cdp_tmp.push( cdp_futurs );
				   } );
			       } );
			       // Et voici tous les créneaux possibles !
			       $scope.creneaux_devoirs_possibles = cdp_tmp;

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
				       Documents.ajout_au_cahier_de_textes( $scope.classe.id, hash )
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
				   var responses = Documents.upload_dans_cahier_de_textes( $scope.classe.id, fichiers );
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
			       $scope.ajout_devoir = function( where ) {
				   var devoir = new Devoirs( {
				       cours_id: $scope.cours.id,
				       date_due: $filter( 'date' )( $scope.creneau.heure_debut, 'yyyy-MM-dd' ),
				       type_devoir_id: _($scope.types_de_devoir).last().id,
				       creneau_emploi_du_temps_id: $scope.creneau.id
				   } );
				   devoir.create = true;
				   where.unshift( devoir );
				   if ( where === $scope.cours.devoirs ) {
				       $scope.accordion_cours_devoirs_open = false;
				   }
			       };

			       $scope.dupliquer = function () {
				   _( $scope.creneaux_similaires.selected ).each( function ( creneau_cible ) {
				       $scope.cours.$copie( {
					   regroupement_id: creneau_cible.regroupement_id,
					   creneau_emploi_du_temps_id: creneau_cible.creneau_emploi_du_temps_id,
					   date: creneau_cible.start
				       } );
				   } );
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
