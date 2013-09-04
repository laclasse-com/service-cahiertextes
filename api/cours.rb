# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  # API d'accès aux cours (séquences pédagogiques)
  # Utilisée par les :
  #   - élèves pour consultation
  #   - enseignants pour consultation et édition
  #   - principaux pour consultation et validation
  class CoursAPI < Grape::API
    format :json

    ############ POST ############
    desc 'renvoi le détail d\'une séquence pédagogique'
    params {
      requires :id, desc: 'id du cours'
    }
    get '/:id' do
      # FIXME: gestion des droits
      if Cours[ params[:id] ].nil? || Cours[ params[:id] ].deleted
        error!( 'Cours inconnu', 404 )
      else
        cours = Cours[ params[:id] ]
        unless cours.nil?
          hash = cours.to_hash
          hash[:ressources] = cours.ressources
          hash
        end
      end
    end

    ############ POST ############
    desc 'renseigne une séquence pédagogique'
    params {
      requires :cahier_de_textes_id
      requires :creneau_emploi_du_temps_id
      requires :date_cours, type: Date
      requires :contenu
      optional :ressources
    }
    post do
      # TODO: gestion des droits
      cours = Cours.create( cahier_de_textes_id: params[:cahier_de_textes_id],
                            creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
                            date_cours: params[:date_cours].to_s,
                            date_creation: Time.now,
                            contenu: params[:contenu] )

      params[:ressources] && params[:ressources].each do
        |ressource|
        cours.add_ressource( Ressource.create( label: ressource['label'],
                                               url: ressource['url'] ) )
      end
    end

    desc 'modifie une séquence pédagogique'
    params {
      requires :id
      requires :contenu
      optional :ressources
    }
    put '/:id' do
      # FIXME: gestion des droits
      cours = Cours[ params[:id] ]

      unless cours.nil?
        cours.contenu = params[:contenu]
        cours.date_modification = Time.now

        params[:ressources] && params[:ressources].each do
          |ressource|
          cours.add_ressource( Ressource.create( label: ressource['label'],
                                                 url: ressource['url'] ) )
        end

        cours.save
      end
    end

    desc 'valide une séquence pédagogique'
    params {
      requires :id
    }
    put '/:id/valide' do
      # FIXME: gestion des droits
      cours = Cours[ params[:id] ]

      unless cours.nil?
        cours.date_validation = Time.now

        cours.save
      end
    end

    desc 'efface une séquence pédagogique'
    params {
      requires :id
    }
    delete '/:id' do
      # FIXME: gestion des droits
      cours = Cours[ params[:id] ]

      unless cours.nil?
        cours.update(deleted: true)
        cours.date_modification = Time.now

        cours.save
      end
    end

  end
end
