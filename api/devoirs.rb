# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  # API d'accès aux devoirs
  # Utilisée par les :
  #   - élèves pour consultation et gestion todo-list
  #   - enseignants pour consultation et édition
  #   - principaux pour consultation
  class DevoirsAPI < Grape::API

    desc 'renvoi le détail d\'un devoir'
    params {
      requires :eleve_id
      optional :from, type: Date
      optional :to, type: Date
    }
    get '/' do

      # TODO: get from eleve
      regroupement_id = CreneauEmploiDuTempsRegroupement
        .select(:regroupement_id)
        .map { |r| r.regroupement_id }
        .sample

      Devoir.select(:devoirs__id,
                    :devoirs__cours_id,
                    :devoirs__type_devoir_id,
                    :devoirs__contenu,
                    :devoirs__date_creation,
                    :devoirs__date_modification,
                    :devoirs__date_validation,
                    :devoirs__date_due,
                    :devoirs__temps_estime)
        .join(:cours, id: :cours_id)
        .join(:creneaux_emploi_du_temps, id: :creneau_emploi_du_temps_id)
        .join(:creneaux_emploi_du_temps_regroupements, creneau_emploi_du_temps_id: :id)
        .where( regroupement_id: regroupement_id )
        .map { |devoir|
        hash = devoir.to_hash
        hash[:ressources] = devoir.ressources
        hash[:fait] = devoir.fait_par?( params[ :eleve_id ] )

        hash
      }
    end

    desc 'renvoi le détail d\'un devoir'
    params {
      requires :id
    }
    get '/:id' do
      devoir = Devoir[ params[:id] ]
      if devoir.nil?
        error!( 'Devoir inconnu', 404 )
      else
        # TODO: replace with real ID
        eleve_id = 1

        hash = devoir.to_hash
        hash[:ressources] = devoir.ressources
        hash[:fait] = devoir.fait_par?( eleve_id )

        hash
      end
    end

    desc 'renseigne un devoir'
    params {
      requires :cours_id
      requires :type_devoir_id
      requires :contenu
      requires :date_due, type: Date
      optional :ressources
    }
    post  do
      if Cours[ params[:cours_id] ].nil?
        error!( 'Cours inconnu', 404 )
      else
        devoir = Devoir.create(cours_id: params[:cours_id],
                               type_devoir_id: params[:type_devoir_id],
                               contenu: params[:contenu],
                               date_due: params[:date_due],
                               temps_estime: params[:temps_estime],
                               date_creation: Time.now)

        params[:ressources] && params[:ressources].each do
          |ressource|
          devoir.add_ressource( Ressource.create( label: ressource['label'],
                                                  url: ressource['url'] ) )
        end
      end
    end

    desc 'modifie un devoir'
    params {
      requires :id
      requires :type_devoir_id
      requires :contenu
      requires :date_due, type: Date
      optional :ressources
    }
    put '/:id' do
      devoir = Devoir[ params[:id] ]
      if devoir.nil?
        error!( 'Devoir inconnu', 404 )
      else
        devoir.type_devoir_id = params[:type_devoir_id]
        devoir.contenu = params[:contenu]
        devoir.date_due = params[:date_due]
        devoir.temps_estime = params[:temps_estime]

        params[:ressources] && params[:ressources].each do
          |ressource|
          devoir.add_ressource( Ressource.create( label: ressource['label'],
                                                  url: ressource['url'] ) )
        end

        devoir.date_modification = Time.now
        devoir.save
      end
    end

    desc 'marque un devoir comme fait'
    params {
      requires :id
    }
    put '/:id/fait' do
      # FIXME: get real (Élève) user
      eleve_id = 1

      Devoir[ params[:id] ].fait_par!( eleve_id )
    end

  end
end
