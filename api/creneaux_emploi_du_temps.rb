# -*- coding: utf-8 -*-

require_relative '../models/creneau_emploi_du_temps'

module CahierDeTextesAPI
  module V1
    class CreneauxEmploiDuTempsAPI < Grape::API
      #--------------------------------------------------------------------
      desc 'renvoi un créneau'
      params do
        requires :id, type: Integer

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
        requires :id, type: Integer
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

        optional :regroupement_id, type: String
        optional :salle_id, type: Integer
        optional :enseignant_id, type: String
        optional :semaines_de_presence_regroupement, type: Integer
        optional :semaines_de_presence_enseignant, type: Integer
        optional :semaines_de_presence_salle, type: Integer
      end
      post  do
        user_needs_to_be( %w( ENS DOC ), true )

        etablissement_id = Etablissement[ UAI: user[:user_detailed]['profil_actif']['etablissement_code_uai'] ].id

        creneau = CreneauEmploiDuTemps.create( date_creation: Time.now,
                                               debut: params[:heure_debut],
                                               fin: params[:heure_fin],
                                               jour_de_la_semaine: params[:jour_de_la_semaine] - 1,
                                               matiere_id: params[:matiere_id],
                                               etablissement_id: etablissement_id )

        params[:enseignant_id] = user[:uid] unless params.key? :enseignant_id

        creneau.modifie( params )

        creneau
      end

      desc 'mass creation of créneaux d\'emploi du temps'
      params do
        requires :uai, type: String, desc: 'UAI de l\'établissement'
        requires :creneaux_emploi_du_temps, type: Array do
          requires :jour_de_la_semaine, type: Integer
          requires :heure_debut, type: Time
          requires :heure_fin, type: Time
          requires :matiere_id, type: String
          requires :regroupement_id, type: Integer
          requires :semaines_de_presence_regroupement, type: Integer
          requires :enseignant_id, type: String
          requires :semaines_de_presence_enseignant, type: Integer

          optional :salle_id, type: Integer
          optional :semaines_de_presence_salle, type: Integer
        end
      end
      post '/bulk' do
        etablissement_id = Etablissement[ UAI: params[:uai] ].id

        params[:creneaux_emploi_du_temps].map do |creneau|
          new_creneau = CreneauEmploiDuTemps.create( date_creation: Time.now,
                                                     jour_de_la_semaine: creneau[:jour_de_la_semaine] - 1,
                                                     matiere_id: creneau[:matiere_id],
                                                     debut: creneau[:heure_debut],
                                                     fin: creneau[:heure_fin],
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
        optional :regroupement_id, type: Integer
        optional :previous_regroupement_id, type: Integer
        optional :heure_debut, type: Time
        optional :heure_fin, type: Time
        optional :salle_id, type: Integer
        optional :enseignant_id, type: String
        optional :semaines_de_presence_regroupement, type: Integer
        optional :semaines_de_presence_enseignant, type: Integer
        optional :semaines_de_presence_salle, type: Integer
        optional :jour_de_la_semaine, type: Integer
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

        if creneau.matiere_id.empty? && creneau.cours.empty? && creneau.devoirs.empty?
          creneau.deep_destroy
        else
          creneau.toggle_deleted( params[:date_creneau] )
        end

        creneau
      end
    end
  end
end