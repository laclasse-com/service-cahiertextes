# -*- coding: utf-8 -*-

require_relative '../../models/plage_horaire'
require_relative '../../models/creneau_emploi_du_temps'

module CahierDeTextesAPI
  module V1
    class CreneauxEmploiDuTempsAPI < Grape::API
      #--------------------------------------------------------------------
      desc 'renvoi un créneau'
      params do
        requires :id, type: Fixnum

        optional :expand, type: Boolean
        optional :debut, type: Date
        optional :fin, type: Date
      end
      get '/:id' do
        creneau = CreneauEmploiDuTemps[ params[:id] ]

        error!( 'Créneau inconnu', 404 ) if creneau.nil?

        expand = !params[:expand].nil? && params[:expand] && !params[:debut].nil? && !params[:fin].nil?

        creneau.to_deep_hash( params[:debut], params[:fin], expand )
      end

      #--------------------------------------------------------------------
      desc 'renvoi les créneaux similaires à ce créneau'
      params do
        requires :id, type: Fixnum
        requires :debut, type: Date
        requires :fin, type: Date
      end
      get '/:id/similaires' do
        creneau = CreneauEmploiDuTemps[ params[:id] ]

        error!( 'Créneau inconnu', 404 ) if creneau.nil?

        creneau.similaires( params[:debut], params[:fin], user )
      end

      #--------------------------------------------------------------------
      desc 'crée un créneau'
      params do
        requires :jour_de_la_semaine, type: Integer
        requires :heure_debut, type: Time
        requires :heure_fin, type: Time
        requires :matiere_id, type: String
        requires :regroupement_id, type: Fixnum

        optional :salle_id, type: Fixnum
        optional :enseignant_id, type: String
        optional :semaines_de_presence_regroupement, type: Fixnum
        optional :semaines_de_presence_enseignant, type: Fixnum
        optional :semaines_de_presence_salle, type: Fixnum
      end
      post  do
        user_needs_to_be( %w( ENS DOC ), true )

        etablissement_id = Etablissement[ UAI: user[:user_detailed]['profil_actif']['etablissement_code_uai'] ].id

        creneau = CreneauEmploiDuTemps.create( date_creation: Time.now,
                                               jour_de_la_semaine: params[:jour_de_la_semaine] - 1,
                                               matiere_id: params[:matiere_id],
                                               etablissement_id: etablissement_id )

        params[:enseignant_id] = user[:uid] unless params.key? :enseignant_id

        creneau.modifie( params )

        creneau
      end

      desc 'mass creation of créneaux d\'emploi du temps'
      params do
        requires :creneaux_emploi_du_temps, type: Array do
          requires :jour_de_la_semaine, type: Integer
          requires :heure_debut, type: Time
          requires :heure_fin, type: Time
          requires :matiere_id, type: String
          requires :regroupement_id, type: Fixnum
          requires :semaines_de_presence_regroupement, type: Fixnum
          requires :enseignant_id, type: String
          requires :semaines_de_presence_enseignant, type: Fixnum
          requires :salle_id, type: Fixnum
          requires :semaines_de_presence_salle, type: Fixnum
        end
        requires :uai, type: String, desc: 'UAI de l\'établissement'
      end
      post '/bulk' do
        uai = params.key?( :uai ) ? params[:uai] : user[:user_detailed]['profil_actif']['etablissement_code_uai']

        etablissement_id = Etablissement[ UAI: uai ].id

        params[:creneaux_emploi_du_temps].map do |creneau|
          new_creneau = DataManagement::Accessors.create_or_get( CreneauEmploiDuTemps,
                                                                 jour_de_la_semaine: creneau[:jour_de_la_semaine] - 1,
                                                                 matiere_id: creneau[:matiere_id],
                                                                 etablissement_id: etablissement_id )
          new_creneau.modifie( creneau )

          new_creneau
        end
      end

      #--------------------------------------------------------------------
      desc 'modifie un créneau'
      params do
        requires :id, type: Integer

        optional :matiere_id, type: String
        optional :regroupement_id, type: Fixnum
        optional :previous_regroupement_id, type: Fixnum
        optional :heure_debut, type: Time
        optional :heure_fin, type: Time
        optional :salle_id, type: Fixnum
        optional :enseignant_id, type: String
        optional :semaines_de_presence_regroupement, type: Fixnum
        optional :semaines_de_presence_enseignant, type: Fixnum
        optional :semaines_de_presence_salle, type: Fixnum
      end
      put '/:id'  do
        user_needs_to_be( %w( ENS DOC ), true )

        creneau = CreneauEmploiDuTemps[ params[:id] ]

        error!( 'Créneau inconnu', 404 ) if creneau.nil?

        creneau.modifie( params )

        creneau
      end

      #--------------------------------------------------------------------
      desc 'marque un créneau comme effacé et inversement'
      params do
        requires :id, type: Integer
        requires :date_creneau, type: Date
      end
      delete '/:id' do
        user_needs_to_be( %w( ENS DOC ), true )

        creneau = CreneauEmploiDuTemps[ params[:id] ]

        error!( 'Créneau inconnu', 404 ) if creneau.nil?

        creneau.toggle_deleted( params[:date_creneau] )

        creneau
      end
    end
  end
end
