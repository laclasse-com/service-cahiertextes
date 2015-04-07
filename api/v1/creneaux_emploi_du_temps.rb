# -*- coding: utf-8 -*-

require_relative '../../models/plage_horaire'
require_relative '../../models/creneau_emploi_du_temps'

module CahierDeTextesAPI
  module V1
    class CreneauxEmploiDuTempsAPI < Grape::API

      #--------------------------------------------------------------------
      desc 'renvoi un créneau'
      params {
        requires :id

        optional :expand, type: Boolean
        optional :debut, type: Date
        optional :fin, type: Date
      }
      get '/:id' do
        creneau = CreneauEmploiDuTemps[ params[:id] ]

        error!( 'Créneau inconnu', 404 ) if creneau.nil?

        expand = !params[:expand].nil? && params[:expand] && !params[:debut].nil? && !params[:fin].nil?

        creneau.to_deep_hash( params[:debut], params[:fin], expand )
      end

      #--------------------------------------------------------------------
      desc 'renvoi les créneaux similaires à ce créneau'
      params {
        requires :id
        requires :debut, type: Date
        requires :fin, type: Date
      }
      get '/:id/similaires' do
        creneau = CreneauEmploiDuTemps[ params[:id] ]

        error!( 'Créneau inconnu', 404 ) if creneau.nil?

        creneau.similaires( params[:debut], params[:fin], user )
      end

      #--------------------------------------------------------------------
      desc 'crée un créneau'
      params {
        requires :jour_de_la_semaine, type: Integer
        requires :heure_debut, type: Time
        requires :heure_fin, type: Time
        requires :matiere_id
        requires :regroupement_id

        optional :salle_id
        optional :semaines_de_presence_regroupement, type: Fixnum
        optional :semaines_de_presence_enseignant, type: Fixnum
        optional :semaines_de_presence_salle, type: Fixnum
      }
      post  do
        user_needs_to_be( %w( ENS ), true )

        dummy_PH = PlageHoraire.first

        error!( 'Aucune PlageHoraire définie', 500 ) if dummy_PH.nil?

        creneau = CreneauEmploiDuTemps.create( date_creation: Time.now,
                                               debut: dummy_PH.id,
                                               fin: dummy_PH.id,
                                               jour_de_la_semaine: params[:jour_de_la_semaine] - 1,
                                               matiere_id: params[:matiere_id] )

        params[:enseignant_id] = user[:uid]
        creneau.modifie( params )

        creneau
      end

      #--------------------------------------------------------------------
      desc 'modifie un créneau'
      params {
        requires :id, type: Integer

        optional :matiere_id
        optional :regroupement_id
        optional :previous_regroupement_id
        optional :heure_debut, type: Time
        optional :heure_fin, type: Time
        optional :salle_id
        optional :semaines_de_presence_regroupement, type: Fixnum
        optional :semaines_de_presence_enseignant, type: Fixnum
        optional :semaines_de_presence_salle, type: Fixnum
      }
      put '/:id'  do
        user_needs_to_be( %w( ENS ), true )

        creneau = CreneauEmploiDuTemps[ params[:id] ]

        error!( 'Créneau inconnu', 404 ) if creneau.nil?

        creneau.modifie( params )

        creneau
      end

      #--------------------------------------------------------------------
      desc 'marque un créneau comme éffacé et inversement'
      params {
        requires :id, type: Integer
        requires :date_creneau, type: Date
      }
      delete '/:id' do
        user_needs_to_be( %w( ENS ), true )

        creneau = CreneauEmploiDuTemps[ params[:id] ]

        error!( 'Créneau inconnu', 404 ) if creneau.nil?

        creneau.toggle_deleted( params[:date_creneau] )

        creneau
      end
    end
  end
end
