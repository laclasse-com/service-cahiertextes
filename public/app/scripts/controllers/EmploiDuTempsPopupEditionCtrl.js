'use strict';

angular.module( 'cahierDeTexteApp' )
    .controller( 'EmploiDuTempsPopupEditionCtrl',
		 [ '$scope', '$filter', '$q', '$sce', 'TINYMCE_OPTIONS', '$modalInstance', 'DOCS_URL', 'Documents', 'CreneauEmploiDuTemps', 'Cours', 'Devoirs', 'User', 'cours', 'devoirs', 'types_de_devoir', 'creneau_selectionne', 'raw_data', 'classes', 'matieres',
		   function ( $scope, $filter, $q, $sce, TINYMCE_OPTIONS, $modalInstance, DOCS_URL, Documents, CreneauEmploiDuTemps, Cours, Devoirs, User, cours, devoirs, types_de_devoir, creneau_selectionne, raw_data, classes, matieres ) {
		       // Attention, $scope ici est le scope de la popup, plus celui d'EnseignantCtrl !
		       var scope_popup = $scope;
		       User.get_user().then( function( response ) {
			   scope_popup.current_user = response.data;
		       } );

		       var create_cours = function( creneau ) {
			   var cours = new Cours({
			       cahier_de_textes_id: creneau.cahier_de_textes_id,
			       creneau_emploi_du_temps_id: creneau.id,
			       date_cours: new Date(creneau.heure_debut).toISOString(),
			       date_validation: null
			   });
			   cours.create = true;

			   return cours;
		       };
		       scope_popup.is_dirty = function( item = null ) {
			   if ( item === null || ( item !== null && item.contenu.length > 0 ) ) {
			       scope_popup.dirty = true;
			   } else {
			       scope_popup.dirty = false;
			   }
		       };

		       // Initialisations {{{
		       scope_popup.DOCS_URL_login = $sce.trustAsResourceUrl( DOCS_URL + '/login' );
		       scope_popup.tinyMCEOptions = TINYMCE_OPTIONS;
		       if ( cours === null ) {
			   scope_popup.cours = create_cours( creneau_selectionne );
		       } else {
			   scope_popup.cours = cours;
			   scope_popup.cours.create = false;
		       }
		       // devoirs
		       scope_popup.devoirs = devoirs;
		       scope_popup.types_de_devoir = types_de_devoir;

		       scope_popup.creneau_selectionne = creneau_selectionne;
		       scope_popup.matieres = matieres;
		       scope_popup.classes = classes;
		       scope_popup.creneau_en_creation = scope_popup.creneau_selectionne.matiere_id.length == 0 || scope_popup.creneau_selectionne.regroupement_id === undefined;
		       if ( scope_popup.creneau_en_creation ) {
			   scope_popup.creneau_tmp_heure_debut = $filter('correctTimeZoneToGMT')( scope_popup.creneau_selectionne.heure_debut );
			   scope_popup.creneau_tmp_heure_fin = $filter('correctTimeZoneToGMT')( scope_popup.creneau_selectionne.heure_fin );
		       }
		       scope_popup.matiere_id = scope_popup.creneau_selectionne.matiere_id.length > 0 ? scope_popup.creneau_selectionne.matiere_id : _.chain( scope_popup.matieres ).values().first().value().id;
		       scope_popup.regroupement_id = scope_popup.creneau_selectionne.regroupement_id !== 'undefined' ? parseInt( scope_popup.creneau_selectionne.regroupement_id ) : _( scope_popup.classes ).first().id;
		       scope_popup.classe = _( scope_popup.classes ).findWhere( {
			   id: parseInt( scope_popup.regroupement_id )
		       } );
		       scope_popup.matiere = scope_popup.matieres[ scope_popup.matiere_id ];

		       // Flags et helpers
		       scope_popup.ouvre_sequence_pedagogique = !scope_popup.cours.create;
		       scope_popup.dirty = false;
		       scope_popup.deleted = false;
		       scope_popup.creneau_deleted = false;

		       // fonctions UI pour le temps estimé
		       scope_popup.estimation_over = function ( d, value ) {
			   d.overValue = value;
			   d.minutes = 5 * value;
		       };
		       scope_popup.estimation_leave = function ( d ) {
			   scope_popup.estimation_over( d, d.temps_estime );
		       };

		       _( scope_popup.devoirs ).each( function ( d ) {
			   scope_popup.estimation_leave( d );
		       } );

		       // Fonction UI pour fixer l'id du créneau en fct du choix dans la sbox des créneaux possibles.
		       scope_popup.set_creneau_date_due = function ( devoir ) {
			   // on prend le premier créneau qui correspond à cette date.
			   var creneau_choisi = _( scope_popup.creneaux_devoirs_possibles ).findWhere( {
			       date_due: devoir.date_due
			   } );
			   devoir.creneau_emploi_du_temps_id = creneau_choisi.creneau_emploi_du_temps_id;
			   scope_popup.is_dirty();
		       };


		       scope_popup.erreurs = [];

		       // http://stackoverflow.com/questions/19408883/angularjs-select-not-2-way-binding-to-model
		       scope_popup.scope = scope_popup;
		       //  ^ ^ Cette ligne est peut-être inutile ?

		       scope_popup.creneaux_similaires = _.chain( raw_data )
			   .filter( function ( creneau ) {
			       return ( creneau.id != scope_popup.creneau_selectionne.id )
				   && ( creneau.regroupement_id != scope_popup.regroupement_id )
				   && ( creneau.matiere_id == scope_popup.matiere_id );
			   } )
			   .map( function ( creneau ) {
			       creneau.classe = _( scope_popup.classes ).findWhere( {
				   id: parseInt( creneau.regroupement_id )
			       } );
			       creneau.label_sbox = $filter( 'formateCreneau' )( creneau );
			       return creneau;
			   } )
			   .value();
		       scope_popup.creneaux_similaires.selected = [];

		       //
		       // Constitution de la liste des créneaux possibles pour les dates dues des devoirs.
		       //
		       // 1. sélection des créneaux possibles en fonction du regroupement et de la matière.
		       var creneaux_devoirs_possibles = _.chain( raw_data )
			       .filter( function ( creneau ) {
				   return ( creneau.regroupement_id == scope_popup.regroupement_id ) && ( creneau.matiere_id == scope_popup.matiere_id );
			       } )
			       .map( function ( creneau ) {
				   creneau.classe = _( scope_popup.classes ).findWhere( {
				       id: parseInt( creneau.regroupement_id )
				   } );
				   creneau.date_due = $filter( 'date' )( creneau.start, 'y-MM-dd' );
				   creneau.label_sbox = $filter( 'formateCreneau' )( creneau.start );
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
			       cdp_futurs.label_sbox = $filter( 'formateCreneau' )( cdp_futurs );

			       cdp_tmp.push( cdp_futurs );
			   } );
		       } );
		       // Et voici tous les créneaux possibles !
		       scope_popup.creneaux_devoirs_possibles = cdp_tmp;

		       // Gestion des documents attachés {{{
		       scope_popup.cartable = [];
		       Documents.list_files().success( function ( response ) {
			   scope_popup.cartable = response;
			   scope_popup.cartable.files = _.chain( scope_popup.cartable.files )
			       .rest()
			       .value()
			       .map( function ( elt ) {
				   elt.children = [];
				   return elt;
			       } );
		       } );

		       scope_popup.add_ressource = function ( item, name, hash ) {
			   if ( item.ressources === undefined ) {
			       item.ressources = [];
			   }
			   if ( _( item.ressources ).findWhere( {
			       hash: hash
			   } ) === undefined ) {
			       Documents.ajout_au_cahier_de_textes( scope_popup.classe.id, hash )
				   .success( function ( response ) {
				       item.ressources.push( {
					   name: name,
					   hash: _( response.added ).first().hash,
					   url: $sce.trustAsResourceUrl( DOCS_URL + '/api/connector?cmd=file&target=' + _( response.added ).first().hash )
				       } );
				       scope_popup.is_dirty();
				   } );
			   }
		       };

		       scope_popup.upload_and_add_ressource = function ( item, fichiers ) {
			   if ( item.ressources === undefined ) {
			       item.ressources = [];
			   }
			   var responses = Documents.upload_dans_cahier_de_textes( scope_popup.classe.id, fichiers );
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
					       scope_popup.is_dirty();
					   }
				       } );
				   } )
				   .error( function ( response ) {
				       console.debug( response.error );
				   } );
			   }
		       };

		       scope_popup.remove_ressource = function ( item, hash ) {
			   item.ressources = _( item.ressources ).reject( function ( ressource ) {
			       return ressource.hash == hash;
			   } );
			   scope_popup.is_dirty();
		       };

		       scope_popup.treeClicked = function ( noeud ) {
			   if ( noeud.mime === 'directory' ) {
			       Documents.list_files( noeud.hash ).then( function ( response ) {
				   _.chain( response.data.files )
				       .rest()
				       .each( function ( elt ) {
					   elt.children = [];
					   noeud.children.push( elt );
					   scope_popup.selectNodeHead( noeud );
				       } );
			       } );
			   }
		       };
		       scope_popup.treeOptions = {
			   nodeChildren: "children",
			   dirSelectable: true
		       };
		       // }}}

		       // fonctions d'événements GUI {{{
		       scope_popup.toggle_sequence_pedagogique = function() {
			   scope_popup.ouvre_sequence_pedagogique = !scope_popup.ouvre_sequence_pedagogique;
		       };
		       scope_popup.ajout_devoir = function () {
			   var devoir = new Devoirs( {
			       cours_id: scope_popup.cours.id,
			       date_due: $filter( 'date' )( scope_popup.creneau_selectionne.start, 'yyyy-MM-dd' ),
			       type_devoir_id: _(scope_popup.types_de_devoir).last().id,
			       creneau_emploi_du_temps_id: scope_popup.creneau_selectionne.id
			   } );
			   devoir.create = true;

			   scope_popup.devoirs.unshift( devoir );
		       };

		       scope_popup.dupliquer = function () {
			   _( scope_popup.creneaux_similaires.selected ).each( function ( creneau_cible ) {
			       scope_popup.cours.$copie( {
				   regroupement_id: creneau_cible.regroupement_id,
				   creneau_emploi_du_temps_id: creneau_cible.creneau_emploi_du_temps_id
			       } );
			   } );
		       };

		       scope_popup.fermer = function () {
			   $modalInstance.close( scope_popup );
		       };

		       scope_popup.effacer_cours = function () {
			   scope_popup.cours.$delete()
			       .then( function () {
				   _( scope_popup.devoirs ).each( function ( devoir ) {
				       devoir.$delete();
				   } );
				   scope_popup.deleted = true;
				   scope_popup.fermer();
			       } );
		       };

		       scope_popup.effacer_devoir = function ( devoir ) {
			   devoir.$delete().then( function() {
			       scope_popup.devoirs = _( scope_popup.devoirs )
				   .reject( function( devoir ) {
				       return devoir.deleted;
				   });
			   });
		       };

		       scope_popup.effacer_creneau = function () {
			   CreneauEmploiDuTemps.delete( {
			       id: scope_popup.creneau_selectionne.id,
			       date_creneau: $scope.cours.date_cours
			   } )
			       .$promise.then( function () {
				   scope_popup.fermer();
			       } );
		       };

		       scope_popup.annuler = function () {
			   if ( scope_popup.creneau_en_creation ) {
			       scope_popup.effacer_creneau();
			   } else {
			       scope_popup.dirty = false;
			       scope_popup.fermer();
			   }
		       };

		       scope_popup.valider = function () {
			   // réinitialisation des erreurs
			   scope_popup.erreurs = [];

			   if ( scope_popup.matiere_id !== '' && scope_popup.regroupement_id !== '' ) {
			       if ( scope_popup.creneau_en_creation ) {
				   scope_popup.creneau_selectionne.matiere_id = scope_popup.matiere_id;
				   scope_popup.creneau_selectionne.regroupement_id = scope_popup.regroupement_id;
				   scope_popup.creneau_selectionne.heure_debut = $filter('correctTimeZone')( scope_popup.creneau_tmp_heure_debut );
				   scope_popup.creneau_selectionne.heure_fin = $filter('correctTimeZone')( scope_popup.creneau_tmp_heure_fin );

				   scope_popup.creneau_selectionne.$update();
			       }

			       // traitement de la séquence pédagogique
			       var promesse = $q.when( true );
			       if ( _( scope_popup.cours ).has( 'contenu' ) && ( scope_popup.cours.contenu.length > 0 ) ) {
				   scope_popup.is_dirty();

				   if ( scope_popup.cours.create ) {
				       scope_popup.cours.cahier_de_textes_id = _( scope_popup.classes ).findWhere( {
					   id: scope_popup.regroupement_id
				       } ).cahier_de_textes_id;
				       scope_popup.cours.creneau_emploi_du_temps_id = scope_popup.creneau_selectionne.id;
				       promesse = scope_popup.cours.$save();
				   } else {
				       promesse = scope_popup.cours.$update();
				   }
			       }

			       promesse.then( function ( cours_from_DB ) {
				   // traitement des devoirs attachés
				   var promesses = [];
				   scope_popup.devoirs = _( scope_popup.devoirs )
				       .map( function ( devoir ) {
					   if ( _( devoir ).has( 'contenu' ) && ( devoir.contenu.length > 0 ) ) {
					       // FIXME: on $save() ou $update() tous les devoirs qu'ils aient été modifiés ou non
					       devoir.dirty = true;

					       var prom = $q.defer();
					       if ( devoir.create ) {
						   devoir.cours_id = cours_from_DB.id;
						   devoir.$save().then( function success( result ) {
						       devoir.id = result.id;
						       prom.resolve( result );
						   }, function ( response ) {
						       scope_popup.erreurs.unshift( {
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
						       scope_popup.erreurs.unshift( {
							   status: response.status,
							   message: response.data.error
						       } );
						       prom.reject( response );
						   } );
					       }

					       promesses.push( prom.promise );
					   }
					   return devoir;
				       } );

				   $q.all( promesses ).then( function () {
				       scope_popup.fermer();
				   } );
			       } );
			   } else {
			       scope_popup.erreurs.push( {
				   'message': 'Aucune matière ou classe défini'
			       } );
			   }
		       };
		       // }}}
		   }
			   ] );
