# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    # API d'accès aux cours (séquences pédagogiques)
    # Utilisée par les :
    #   - élèves pour consultation
    #   - enseignants pour consultation et édition
    #   - principaux pour consultation et validation
    class CoursAPI < Grape::API
      format :json

      before do
        # pas de gestion restriction d'accès sur les get
        next if request.get?

        user_needs_to_be( %w( ENS DOC DIR ), false )
      end

      desc 'renvoi le détail d\'une séquence pédagogique'
      params do
        requires :id, desc: 'id du cours'
      end
      get '/:id' do
        cours = Cours[ params[:id] ]
        error!( 'Cours inconnu', 404 ) if cours.nil? ||
                                          ( cours.deleted && cours.date_modification < UNDELETE_TIME_WINDOW.minutes.ago )

        cours.to_deep_hash
      end

      desc 'renseigne une séquence pédagogique'
      params do
        requires :regroupement_id
        requires :creneau_emploi_du_temps_id
        requires :date_cours, type: Date
        requires :contenu

        optional :ressources
      end
      post do
        user_needs_to_be( %w( ENS DOC ), true )

        error!( 'Créneau invalide', 409 ) if CreneauEmploiDuTemps[ params[:creneau_emploi_du_temps_id] ].nil?

        # FIXME: do away with this, pass :regroupement_id to Cours and let it deal with it
        cahier_de_textes = CahierDeTextes.where( regroupement_id: params[:regroupement_id] ).first
        cahier_de_textes = CahierDeTextes.create( date_creation: Time.now,
                                                  regroupement_id: params[:regroupement_id] ) if cahier_de_textes.nil?
        cours = Cours.create( enseignant_id: user[:uid],
                              cahier_de_textes_id: cahier_de_textes.id,
                              creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
                              date_cours: params[:date_cours].to_s,
                              date_creation: Time.now,
                              contenu: '' )

        cours.modifie( params )

        cours.to_deep_hash
      end

      desc 'modifie une séquence pédagogique'
      params do
        requires :id, type: Integer
        requires :contenu, type: String

        optional :ressources, type: Array
      end
      put '/:id' do
        user_needs_to_be( %w( ENS DOC ), true )

        cours = Cours[ params[:id] ]

        error!( 'Cours inconnu', 404 ) if cours.nil?
        error!( 'Cours visé non modifiable', 401 ) unless cours.date_validation.nil?

        cours.modifie( params )

        cours.to_deep_hash
      end

      desc 'valide une séquence pédagogique'
      params do
        requires :id
      end
      put '/:id/valide' do
        user_needs_to_be( %w( DIR ), true )

        cours = Cours[ params[:id] ]
        error!( 'Cours inconnu', 404 ) if cours.nil?

        cours.toggle_validated

        cours.to_deep_hash
      end

      desc 'copie une séquence pédagogique'
      params do
        requires :id, type: Integer
        requires :creneau_emploi_du_temps_id
        requires :regroupement_id
        requires :date, type: Date
      end
      put '/:id/copie/regroupement/:regroupement_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date/:date' do
        user_needs_to_be( %w( ENS DOC ), true )

        cours = Cours[ params[:id] ]

        error!( 'Cours inconnu', 404 ) if cours.nil?

        nouveau_cours = cours.copie( params[:regroupement_id], params[:creneau_emploi_du_temps_id], params[:date] )

        hash = cours.to_deep_hash
        hash[:copie_id] = nouveau_cours[:id]

        hash
      end

      desc 'marque une séquence pédagogique comme éffacée et inversement'
      params do
        requires :id
      end
      delete '/:id' do
        user_needs_to_be( %w( ENS DOC ), true )

        cours = Cours[ params[:id].to_i ]

        error!( 'Cours inconnu', 404 ) if cours.nil?
        error!( 'Cours visé non modifiable', 401 ) unless cours.date_validation.nil?

        cours.toggle_deleted

        cours.to_deep_hash
      end
    end
  end
end
