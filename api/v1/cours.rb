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
        error!( 'Cours inconnu', 404 ) if cours.nil? || cours.deleted

        hcours = cours.to_deep_hash
        # BUG: to_deep_hash casse les hash des ressources
        hcours[:ressources] = cours.ressources.map do |ressource|
          ressource.to_hash
        end

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
        cours = Cours[ params[:id] ]

        unless cours.nil?
          if cours.date_validation.nil?
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
      end

      desc 'valide une séquence pédagogique'
      params {
        requires :id
      }
      put '/:id/valide' do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'DIR' )

        cours = Cours[ params[:id] ]

        unless cours.nil?
          cours.date_validation = Time.now if cours.date_validation.nil?

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

            target_cours.ressources.each do
              |ressource|
              target_cours.add_ressource( ressource )
            end

            target_cours.to_deep_hash
          end
        end
      end

      desc 'efface une séquence pédagogique'
      params {
        requires :id
      }
      delete '/:id' do
        cours = Cours[ params[:id] ]

        unless cours.nil?
          if cours.date_validation.nil?
            cours.update(deleted: true)
            cours.date_modification = Time.now

            cours.save

            cours.to_deep_hash
          end
        end
      end
    end
  end
end
