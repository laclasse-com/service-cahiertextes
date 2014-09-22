'use strict';

angular.module('cahierDeTexteApp')
    .service('PopupsCreneau',
	     [ '$modal', 'APP_PATH',
	       function( $modal, APP_PATH ) {
		   this.edition = function ( raw_data, matieres, classes, creneau, cours, devoirs, popup_callback, popup_ouverte ) {
		       popup_ouverte = true;
		       $modal.open( {
			   templateUrl: APP_PATH + '/app/views/enseignant/popup_edition.html',
			   controller: 'PopupEditionCtrl',
			   resolve: {
			       raw_data   : function () { return raw_data; },
			       matieres   : function () { return matieres; },
			       classes    : function () { return classes; },
			       creneau    : function () { return creneau; },
			       cours	     : function () { return cours; },
			       devoirs    : function () { return devoirs; }
			   },
			   backdrop: 'static'
		       } )
			   .result.then( // éxécuté à la fermeture de la popup
			       function ( scope_popup ) {
				   popup_callback( scope_popup );
			       } )
			   .finally( function() {
			       popup_ouverte = false;
			   } );
		   };

		   this.display = function( titre, cours, devoirs, popup_callback, popup_ouverte ) {
		       popup_ouverte = true;
		       $modal.open( { templateUrl: APP_PATH + '/app/views/eleve/popup_display.html',
				      controller: 'PopupDisplayCtrl',
				      resolve: { titre  : function() { return titre; },
						 cours  : function() { return cours; },
						 devoirs: function() { return devoirs; } },
				      backdrop: 'static' }
				  )
			   .result.then( function( scope_popup ) {
			       popup_callback( scope_popup );
			   } )
			   .finally( function() {
			       popup_ouverte = false;
			   } );
		   };

	       } ] );
