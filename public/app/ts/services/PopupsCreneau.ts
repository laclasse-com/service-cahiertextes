'use strict';

angular.module( 'cahierDeTextesClientApp' )
  .service( 'PopupsCreneau',
  [ '$uibModal', 'toastr', 'POPUP_ACTIONS', 'APP_PATH',
    function( $uibModal, toastr, POPUP_ACTIONS, APP_PATH ) {
      var open_modal = function( params, popup_callback, popup_ouverte ) {
        popup_ouverte = true;
        $uibModal.open( params )
          .result.then( function( scope_popup ) {
            // Toast actions done
            _( scope_popup.actions_done ).each( function( action ) {
              switch ( action ) {
                case POPUP_ACTIONS.CANCELLED:
                  toastr.info( '', 'Annulation.' );
                  break;
                case POPUP_ACTIONS.CRENEAU_DELETED:
                  toastr.info( '', 'Créneau supprimé.' );
                  break;
                case POPUP_ACTIONS.CRENEAU_MODIFIED:
                  toastr.info( '', 'Créneau mis à jour.' );
                  break;
                case POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_CREATED:
                  toastr.success( '', 'Séquence pédagogique créée.' );
                  break;
                case POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_MODIFIED:
                  toastr.success( '', 'Séquence pédagogique modifiée.' );
                  break;
                case POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_DUPLICATED:
                  // toastr.success( '', 'Séquence pédagogique copiée.');
                  break;
                case POPUP_ACTIONS.SEQUENCE_PEDAGOGIQUE_DELETED:
                  toastr.success( '', 'Séquence pédagogique supprimée.' );
                  break;
                case POPUP_ACTIONS.DEVOIR_CREATED:
                  toastr.success( '', 'Devoir créé.' );
                  break;
                case POPUP_ACTIONS.DEVOIR_MODIFIED:
                  toastr.success( '', 'Devoir modifié.' );
                  break;
                case POPUP_ACTIONS.DEVOIR_DUPLICATED:
                  // toastr.success( '', 'Devoir copié.');
                  break;
                case POPUP_ACTIONS.DEVOIR_DELETED:
                  toastr.success( '', 'Devoir supprimé.' );
                  break;
              }
            } );

            // invoke callback
            popup_callback( scope_popup );
          } )
          .finally( function() {
            popup_ouverte = false;
          } );
      };

      this.edition = function( raw_data, matieres, classes, creneau, cours, devoirs, popup_callback, popup_ouverte ) {
        open_modal( {
          templateUrl: APP_PATH + '/app/views/popup_edition.html',
          controller: 'PopupEditionCtrl',
          resolve: {
            raw_data: function() { return raw_data; },
            matieres: function() { return matieres; },
            classes: function() { return classes; },
            creneau: function() { return creneau; },
            cours: function() { return cours; },
            devoirs: function() { return devoirs; }
          },
          backdrop: 'static'
        },
          popup_callback,
          popup_ouverte );
      };

      this.display = function( titre, cours, devoirs, popup_callback, popup_ouverte ) {
        open_modal( {
          templateUrl: APP_PATH + '/app/views/popup_display.html',
          controller: 'PopupDisplayCtrl',
          resolve: {
            titre: function() { return titre; },
            cours: function() { return cours; },
            devoirs: function() { return devoirs; }
          },
          backdrop: 'static'
        },
          popup_callback,
          popup_ouverte );
      };

    }] );
