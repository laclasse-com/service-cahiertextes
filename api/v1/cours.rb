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
        if Cours[ params[:id] ].nil? || Cours[ params[:id] ].deleted
          error!( 'Cours inconnu', 404 )
        else
          cours = Cours[ params[:id] ]

          cours.to_deep_hash unless cours.nil?
        end
      end

      desc 'renvoi les devoirs liés à une séquence pédagogique'
      params {
        requires :id, desc: 'id du cours'
      }
      get '/:id/devoirs' do
        if Cours[ params[:id] ].nil? || Cours[ params[:id] ].deleted
          error!( 'Cours inconnu', 404 )
        else
          devoirs = Devoir.where( cours_id: params[:id] )

          devoirs.map { | devoir|
            devoir.to_deep_hash
          }
        end
      end

      desc 'renseigne une séquence pédagogique'
      params {
        requires :cahier_de_textes_id
        requires :creneau_emploi_du_temps_id
        requires :date_cours, type: Date
        requires :contenu

        optional :ressources
      }
      post do
        cours = Cours.create(  enseignant_id: user.uid,
                               cahier_de_textes_id: params[:cahier_de_textes_id],
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
      }
      put '/:id/copie/regroupement/:regroupement_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id' do
        cours = Cours[ params[:id] ]

        unless cours.nil?
          new_cours = Cours.create(  cahier_de_textes_id: CahierDeTextes.where(regroupement_id: params[:regroupement_id]).first.id,
                                     creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
                                     date_cours: cours.date_cours, # FIXME: comment la calculer ?
                                     date_creation: Time.now,
                                     contenu: params[:contenu],
                                     enseignant_id: cours.enseignant_id )

          cours.ressources.each do
            |ressource|
            new_cours.add_ressource( ressource )
          end

          new_cours.to_deep_hash
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
