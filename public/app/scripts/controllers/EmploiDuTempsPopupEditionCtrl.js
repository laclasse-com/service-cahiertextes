'use strict';

angular.module( 'cahierDeTexteApp' )
    .controller( 'EmploiDuTempsPopupEditionCtrl',
		 [ '$scope', '$filter', '$q', '$sce', '$modalInstance', 'TINYMCE_OPTIONS', 'DOCS_URL', 'Documents', 'API', 'CreneauEmploiDuTemps', 'Cours', 'Devoirs', 'User', 'cours', 'devoirs', 'creneau_selectionne', 'raw_data', 'classes', 'matieres',
		   function ( $scope, $filter, $q, $sce, $modalInstance, TINYMCE_OPTIONS, DOCS_URL, Documents, API, CreneauEmploiDuTemps, Cours, Devoirs, User, cours, devoirs, creneau_selectionne, raw_data, classes, matieres ) {
		       User.get_user().then( function( response ) {
			   $scope.current_user = response.data;

			   var create_cours = function( creneau ) {
			       var cours = new Cours( { cahier_de_textes_id: creneau.cahier_de_textes_id,
							creneau_emploi_du_temps_id: creneau.id,
							date_cours: new Date(creneau.heure_debut).toISOString(),
							date_validation: null,
							enseignant_id: $scope.current_user.uid } );
			       cours.create = true;

			       return cours;
			   };
			   $scope.is_dirty = function( item ) {
			       item = typeof item !== 'undefined' ? item : null;
			       $scope.dirty = $scope.dirty || ( item === null || ( item !== null && item.contenu.length > 0 ) );
			   };

			   // Initialisations {{{
			   $scope.DOCS_URL_login = $sce.trustAsResourceUrl( DOCS_URL + '/login' );
			   $scope.tinyMCEOptions = TINYMCE_OPTIONS;
			   if ( cours === null ) {
			       $scope.cours = create_cours( creneau_selectionne );
			   } else {
			       $scope.cours = cours;
			       $scope.cours.create = false;
			   }
			   // devoirs
			   $scope.devoirs = devoirs;
			   $scope.types_de_devoir = API.query_types_de_devoir();

			   $scope.creneau_selectionne = creneau_selectionne;
			   $scope.matieres = matieres;
			   $scope.classes = classes;
			   $scope.creneau_en_creation = $scope.creneau_selectionne.matiere_id.length == 0 || $scope.creneau_selectionne.regroupement_id === undefined;
			   $scope.creneau_tmp_heure_debut = $filter('correctTimeZoneToGMT')( $scope.creneau_selectionne.heure_debut );
			   $scope.creneau_tmp_heure_fin = $filter('correctTimeZoneToGMT')( $scope.creneau_selectionne.heure_fin );
			   $scope.matiere_id = $scope.creneau_selectionne.matiere_id.length > 0 ? $scope.creneau_selectionne.matiere_id : _.chain( $scope.matieres ).values().first().value().id;
			   $scope.regroupement_id = $scope.creneau_selectionne.regroupement_id !== 'undefined' ? parseInt( $scope.creneau_selectionne.regroupement_id ) : _( $scope.classes ).first().id;
			   $scope.classe = _( $scope.classes ).findWhere( {
			       id: parseInt( $scope.regroupement_id )
			   } );
			   $scope.matiere = $scope.matieres[ $scope.matiere_id ];

			   // Gestion des semaines actives
			   var fixnum_to_bitfield = function( fixnum ) {
			       return _(fixnum.toString(2).split('').map( function( e ) { return parseInt( e ); } )).rest();
			   };
			   var bitfield_to_fixnum = function( bitfield ) {
			       return parseInt( '1' + bitfield.join(''), 2 );
			   };
			   $scope.semaines_actives = { regroupement: [] };
			   $scope.apply_template = function( template_name ) {
			       var template = [];
			       switch( template_name ) {
			       case 'semaine_A':
				   _(26).times( function() {
				       template.push( 1 );
				       template.push( 0 );
				   });
				   $scope.semaines_actives.regroupement = template;
				   break;
			       case 'semaine_B':
				   _(26).times( function() {
				       template.push( 0 );
				       template.push( 1 );
				   });
				   $scope.semaines_actives.regroupement = template;
				   break;
			       case 'initialize':
				   $scope.semaines_actives.regroupement = fixnum_to_bitfield( $scope.creneau_en_creation ? 9007199254740991 : _(creneau_selectionne.regroupements).findWhere( { regroupement_id: creneau_selectionne.regroupement_id } ).semaines_de_presence );
				   break;
			       }
			   };
			   $scope.apply_template( 'initialize' );

			   // Flags et helpers
			   $scope.dirty = false;
			   $scope.deleted = false;
			   $scope.creneau_deleted = false;

			   $scope.groups = { semaines_actives: { ouvert: $scope.creneau_en_creation },
						  sequence_pedagogique: { ouvert: !$scope.cours.create },
						  devoirs: { ouvert: !$scope.cours.create && $scope.devoirs.length > 0 } };

			   // fonctions UI pour le temps estimé
			   $scope.estimation_over = function ( d, value ) {
			       d.overValue = value;
			       d.minutes = 5 * value;
			   };
			   $scope.estimation_leave = function ( d ) {
			       $scope.estimation_over( d, d.temps_estime );
			   };

			   _( $scope.devoirs ).each( function ( d ) {
			       $scope.estimation_leave( d );
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


			   $scope.erreurs = [];

			   // http://stackoverflow.com/questions/19408883/angularjs-select-not-2-way-binding-to-model
			   $scope.scope = $scope;
			   //  ^ ^ Cette ligne est peut-être inutile ?

			   $scope.creneaux_similaires = _.chain( raw_data )
			       .filter( function ( creneau ) {
				   return ( creneau.id != $scope.creneau_selectionne.id )
				       && ( creneau.regroupement_id != $scope.regroupement_id )
				       && ( creneau.matiere_id == $scope.matiere_id );
			       } )
			       .map( function ( creneau ) {
				   creneau.classe = _( $scope.classes ).findWhere( {
				       id: parseInt( creneau.regroupement_id )
				   } );
				   creneau.label_sbox = $filter( 'formateCreneau' )( creneau );
				   return creneau;
			       } )
			       .value();
			   $scope.creneaux_similaires.selected = [];

			   //
			   // Constitution de la liste des créneaux possibles pour les dates dues des devoirs.
			   //
			   // 1. sélection des créneaux possibles en fonction du regroupement et de la matière.
			   var creneaux_devoirs_possibles = _.chain( raw_data )
				   .filter( function ( creneau ) {
				       return ( creneau.regroupement_id == $scope.regroupement_id ) && ( creneau.matiere_id == $scope.matiere_id );
				   } )
				   .map( function ( creneau ) {
				       creneau.classe = _( $scope.classes ).findWhere( {
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
			   $scope.creneaux_devoirs_possibles = cdp_tmp;

			   // {{{ Gestion des documents attachés
			   $scope.cartable = {};
			   $scope.cartable.expandedNodes = [];
			   Documents.list_files().success( function ( response ) {
			       $scope.cartable = response;
			       $scope.cartable.files = _.chain( $scope.cartable.files )
				   .rest()
				   .value()
				   .map( function ( elt ) {
				       elt.children = [];
				       return elt;
				   } );
			   } );

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
			   $scope.ajout_devoir = function () {
			       var devoir = new Devoirs( {
				   cours_id: $scope.cours.id,
				   date_due: $filter( 'date' )( $scope.creneau_selectionne.start, 'yyyy-MM-dd' ),
				   type_devoir_id: _($scope.types_de_devoir).last().id,
				   creneau_emploi_du_temps_id: $scope.creneau_selectionne.id
			       } );
			       devoir.create = true;

			       $scope.devoirs.unshift( devoir );

			       // Contre-intuitif certes, mais comme on clique dans le heading
			       // de l'accordéon du coup ça marche comme ça
			       $scope.groups.devoirs.ouvert = false;
			   };

			   $scope.dupliquer = function () {
			       _( $scope.creneaux_similaires.selected ).each( function ( creneau_cible ) {
				   $scope.cours.$copie( {
				       regroupement_id: creneau_cible.regroupement_id,
				       creneau_emploi_du_temps_id: creneau_cible.creneau_emploi_du_temps_id
				   } );
			       } );
			   };

			   $scope.fermer = function () {
			       $modalInstance.close( $scope );
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

			   $scope.effacer_devoir = function ( devoir ) {
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

			   $scope.effacer_creneau = function () {
			       CreneauEmploiDuTemps.delete( {
				   id: $scope.creneau_selectionne.id,
				   date_creneau: $scope.cours.date_cours
			       } )
				   .$promise.then( function () {
				       $scope.fermer();
				   } );
			   };

			   $scope.annuler = function () {
			       if ( $scope.creneau_en_creation && $scope.creneau_selectionne.matiere_id === '' && $scope.creneau_selectionne.regroupement_id === 'undefined' ) {
				   $scope.effacer_creneau();
			       } else {
				   $scope.dirty = false;
				   $scope.fermer();
			       }
			   };

			   $scope.valider = function () {
			       // réinitialisation des erreurs
			       $scope.erreurs = [];

			       if ( $scope.creneau_en_creation ) {
				   $scope.creneau_selectionne.matiere_id = $scope.matiere_id;
				   $scope.creneau_selectionne.regroupement_id = $scope.regroupement_id;
				   $scope.creneau_selectionne.heure_debut = $filter('correctTimeZone')( $scope.creneau_tmp_heure_debut );
				   $scope.creneau_selectionne.heure_fin = $filter('correctTimeZone')( $scope.creneau_tmp_heure_fin );
				   $scope.creneau_selectionne.semaines_de_presence_regroupement = bitfield_to_fixnum( $scope.semaines_actives.regroupement );

				   $scope.creneau_selectionne.$update();

				   $scope.is_dirty();
			       }

			       // traitement de la séquence pédagogique
			       var promesse = $q.when( true );
			       if ( _( $scope.cours ).has( 'contenu' ) && ( $scope.cours.contenu.length > 0 ) ) {
				   if ( $scope.cours.create ) {
				       $scope.cours.cahier_de_textes_id = _( $scope.classes ).findWhere( {
					   id: $scope.regroupement_id
				       } ).cahier_de_textes_id;
				       $scope.cours.creneau_emploi_du_temps_id = $scope.creneau_selectionne.id;
				       promesse = $scope.cours.$save();
				   } else {
				       promesse = $scope.cours.$update();
				   }

				   $scope.is_dirty();
			       }

			       promesse.then( function ( cours_from_DB ) {
				   // traitement des devoirs attachés
				   var promesses = [];
				   $scope.devoirs = _( $scope.devoirs )
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
					   return devoir;
				       } );

				   $q.all( promesses ).then( function () {
				       $scope.fermer();
				   } );
			       } );
			   };
			   // }}}
		       } );
		   }
			       ] );
