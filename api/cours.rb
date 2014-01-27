# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  # API d'accès aux cours (séquences pédagogiques)
  # Utilisée par les :
  #   - élèves pour consultation
  #   - enseignants pour consultation et édition
  #   - principaux pour consultation et validation
  class CoursAPI < Grape::API
    format :json

    desc 'renvoi le détail d\'une séquence pédagogique'
    params {
      requires :id, desc: 'id du cours'
    }
    get '/:id' do
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

    desc 'renseigne une séquence pédagogique'
    params {
      requires :cahier_de_textes_id
      requires :creneau_emploi_du_temps_id
      requires :date_cours, type: Date
      requires :contenu
      optional :ressources
    }
    post do
       error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS', '0699999Z' ) || user.is?( 'DIR', '0699999Z' )
       # error!( '401 Unauthorized', 401 ) unless user.profils.map {
       #    |profil|
       #    profil['profil_id']
       # }.include? 'ENS'

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

      cours
    end

    desc 'modifie une séquence pédagogique'
    params {
      requires :id, type: Integer
      requires :contenu, type: String
      optional :ressources, type: Array
    }
    put '/:id' do
       error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS', '0699999Z' ) || user.is?( 'DIR', '0699999Z' )

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

        cours
      end
    end

    desc 'valide une séquence pédagogique'
    params {
      requires :id
    }
    put '/:id/valide' do
       error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS', '0699999Z' ) || user.is?( 'DIR', '0699999Z' )

       cours = Cours[ params[:id] ]

      unless cours.nil?
        cours.date_validation = Time.now

        cours.save

        cours
      end
    end

    desc 'copie une séquence pédagogique'
    params {
      requires :id, type: Integer
      requires :creneau_emploi_du_temps_id
      requires :regroupement_id
    }
    put '/:id/copie/regroupement/:regroupement_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id' do
       error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS', '0699999Z' ) || user.is?( 'DIR', '0699999Z' )

       cours = Cours[ params[:id] ]

      unless cours.nil?
        new_cours = Cours.create( cahier_de_textes_id: CahierDeTextes.where(regroupement_id: params[:regroupement_id]).first.id,
                                  creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
                                  date_cours: cours.date_cours, # FIXME: comment la calculer ?
                                  date_creation: Time.now,
                                  contenu: params[:contenu],
                                  enseignant_id: cours.enseignant_id )

        cours.ressources.each do
          |ressource|
          new_cours.add_ressource( ressource )
        end

        Devoir.where( cours_id: cours.id ).all.each {
          |devoir|
          Devoir.create( cours_id: new_cours.id,
                         creneau_emploi_du_temps_id: devoir.creneau_emploi_du_temps_id, # FIXME: à recalculer
                         type_devoir_id: devoir.type_devoir_id,
                         contenu: devoir.contenu,
                         date_creation: Time.now,
                         date_modification: nil,
                         date_validation: nil,
                         date_due: devoir.date_due, # FIXME: à recalculer
                         temps_estime: devoir.temps_estime )
        }
        new_cours
      end
    end

    desc 'efface une séquence pédagogique'
    params {
      requires :id
    }
    delete '/:id' do
       error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS', '0699999Z' ) || user.is?( 'DIR', '0699999Z' )

       cours = Cours[ params[:id] ]

      unless cours.nil?
        cours.update(deleted: true)
        cours.date_modification = Time.now

        cours.save

        cours
      end
    end

  end
end
