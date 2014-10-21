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

        error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS' ) || user.is?( 'DIR' )
      end

      desc 'renvoi le détail d\'une séquence pédagogique'
      params {
        requires :id, desc: 'id du cours'
      }
      get '/:id' do
        cours = Cours[ params[:id] ]
        error!( 'Cours inconnu', 404 ) if cours.nil? || ( cours.deleted && cours.date_modification < UNDELETE_TIME_WINDOW.minutes.ago )

        hcours = cours.to_deep_hash
        # BUG: to_deep_hash casse les hash des ressources
        hcours[:ressources] = cours.ressources.map do |ressource|
          ressource.to_hash
        end
        hcours[:devoirs] = cours.devoirs.select { |devoir| !devoir.deleted || devoir.date_modification > UNDELETE_TIME_WINDOW.minutes.ago }

        hcours
      end

      desc 'renseigne une séquence pédagogique'
      params {
        requires :regroupement_id
        requires :creneau_emploi_du_temps_id
        requires :date_cours, type: Date
        requires :contenu

        optional :ressources
      }
      post do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS' ) || user.admin?

        cahier_de_textes = CahierDeTextes.where( regroupement_id: params[:regroupement_id] ).first
        cahier_de_textes = CahierDeTextes.create( regroupement_id: params[:regroupement_id] ) if cahier_de_textes.nil?
        cours = Cours.create( enseignant_id: user.uid,
                              cahier_de_textes_id: cahier_de_textes.id,
                              creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
                              date_cours: params[:date_cours].to_s,
                              date_creation: Time.now,
                              contenu: params[:contenu] )

        params[:ressources] && params[:ressources].each do
          |ressource|
          cours.add_ressource( Ressource.create(  name: ressource['name'],
                                                  hash: ressource['hash'] ) )
        end

        cours.to_deep_hash
      end

      desc 'modifie une séquence pédagogique'
      params {
        requires :id, type: Integer
        requires :contenu, type: String

        optional :ressources, type: Array
      }
      put '/:id' do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS' ) || user.admin?

        cours = Cours[ params[:id] ]

        unless cours.nil? || !cours.date_validation.nil?
          cours.contenu = params[:contenu]
          cours.date_modification = Time.now

          if params[:ressources]
            cours.remove_all_ressources
            params[:ressources].each do
              |ressource|
              cours.add_ressource( Ressource.create(name: ressource['name'],
                                                    hash: ressource['hash'] ) )
            end
          end

          cours.save

          cours.to_deep_hash
        end
      end

      desc 'valide une séquence pédagogique'
      params {
        requires :id
      }
      put '/:id/valide' do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'DIR' )

        cours = Cours[ params[:id] ]

        unless cours.nil?
          cours.date_validation = cours.date_validation.nil? ? Time.now : nil

          cours.save

          cours.to_deep_hash
        end
      end

      desc 'copie une séquence pédagogique'
      params {
        requires :id, type: Integer
        requires :creneau_emploi_du_temps_id
        requires :regroupement_id
        requires :date, type: Date
      }
      put '/:id/copie/regroupement/:regroupement_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date/:date' do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS' ) || user.admin?

        cours = Cours[ params[:id] ]

        unless cours.nil?
          cahier_de_textes = CahierDeTextes.where( regroupement_id: params[:regroupement_id] ).first
          cahier_de_textes = CahierDeTextes.create( regroupement_id: params[:regroupement_id] ) if cahier_de_textes.nil?

          target_cours = Cours.where( cahier_de_textes_id: cahier_de_textes.id,
                                      creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
                                      date_cours: params[:date] ).first

          if target_cours.nil?
            target_cours = Cours.create( cahier_de_textes_id: cahier_de_textes.id,
                                         creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
                                         date_cours: params[:date],
                                         date_creation: Time.now,
                                         contenu: cours.contenu,
                                         enseignant_id: cours.enseignant_id )

            cours.ressources.each do |ressource|
              target_cours.add_ressource( ressource )
            end

            hcours = cours.to_deep_hash
            # BUG: to_deep_hash casse les hash des ressources
            hcours[:ressources] = cours.ressources.map do |ressource|
              ressource.to_hash
            end
            hcours[:devoirs] = cours.devoirs.select { |devoir| !devoir.deleted || devoir.date_modification > UNDELETE_TIME_WINDOW.minutes.ago }
            hcours[:copie_id] = target_cours.id

            hcours
          end
        end
      end

      desc 'marque une séquence pédagogique comme éffacée et inversement'
      params {
        requires :id
      }
      delete '/:id' do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS' ) || user.admin?

        cours = Cours[ params[:id] ]

        unless cours.nil? || !cours.date_validation.nil?
          cours.update( deleted: !cours.deleted, date_modification: Time.now )
          cours.save

          cours.devoirs.each do |devoir|
            if cours.deleted
              devoir.update( deleted: cours.deleted, date_modification: Time.now )
            elsif devoir.date_modification <= UNDELETE_TIME_WINDOW.minutes.ago
              devoir.update( deleted: cours.deleted, date_modification: Time.now )
            end
            devoir.save
          end

          hcours = cours.to_deep_hash
          hcours[:devoirs] = cours.devoirs.select { |devoir| !devoir.deleted || devoir.date_modification > UNDELETE_TIME_WINDOW.minutes.ago }

          hcours
        end
      end
    end
  end
end
