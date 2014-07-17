# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V0
    # API d'accès aux devoirs
    # Utilisée par les :
    #   - élèves pour consultation et gestion todo-list
    #   - enseignants pour consultation et édition
    #   - principaux pour consultation
    class DevoirsAPI < Grape::API

      desc 'renvoi tous les devoirs concernant l\'utilisateur durant la période donnée'
      get '/' do
        return [] unless user.methods.include? :classes

        regroupements_ids = user.classes.map {
          |classe|
          classe['classe_id']
        }.uniq

        Devoir
          .join(:creneaux_emploi_du_temps_regroupements, creneau_emploi_du_temps_id: :id)
          .where( regroupement_id: regroupements_ids )
          .map { |devoir|
          hash = devoir.to_hash
          hash[:ressources] = devoir.ressources.map { |rsrc| rsrc.to_hash }
          hash[:fait] = devoir.fait_par?( user.uid )

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
          hash = devoir.to_hash
          hash[:ressources] = devoir.ressources

          unless user.nil?
            eleve_id = user.uid
            hash[:fait] = devoir.fait_par?( eleve_id )
          end

          hash
        end
      end

      desc 'renseigne un devoir'
      params {
        requires :type_devoir_id
        requires :contenu
        requires :creneau_emploi_du_temps_id
        requires :date_due, type: Date

        optional :cours_id
        optional :ressources
        optional :temps_estime
      }
      post  do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS' )

        if CreneauEmploiDuTemps[ params[:creneau_emploi_du_temps_id] ].nil?
          error!( 'Paramètres invalides', 404 )
        else
          devoir = Devoir.create( type_devoir_id: params[:type_devoir_id],
                                  creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
                                  contenu: params[:contenu],
                                  date_due: params[:date_due],
                                  temps_estime: params[:temps_estime],
                                  date_creation: Time.now)

          devoir.update( cours_id: params[:cours_id] ) if params[ :cours_id ]

          # 3. traitement des ressources
          params[:ressources] && params[:ressources].each do
            |ressource|
            devoir.add_ressource( Ressource.create(  name: ressource['name'],
                                                     hash: ressource['hash'] ) )
          end

          # FIXME: fuite d'info sur :devoir_todo_items
          devoir.to_json include: Devoir.associations
        end
      end

      desc 'modifie un devoir'
      params {
        requires :id
        requires :type_devoir_id
        requires :contenu
        requires :creneau_emploi_du_temps_id
        requires :date_due, type: Date

        optional :cours_id
        optional :ressources
        optional :temps_estime
      }
      put '/:id' do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS' )

        devoir = Devoir[ params[:id] ]
        if devoir.nil?
          error!( 'Devoir inconnu', 404 )
        else

          devoir.date_due = params[:date_due] if devoir.date_due != params[:date_due]
          devoir.creneau_emploi_du_temps_id = params[:creneau_emploi_du_temps_id] if devoir.creneau_emploi_du_temps_id != params[:creneau_emploi_du_temps_id]

          devoir.type_devoir_id = params[:type_devoir_id] if devoir.type_devoir_id != params[:type_devoir_id]
          devoir.contenu = params[:contenu] if devoir.contenu != params[:contenu]
          devoir.temps_estime = params[:temps_estime] if devoir.temps_estime != params[:temps_estime]

          devoir.update( cours_id: params[:cours_id] ) if params[ :cours_id ]

          params[:ressources].each do
            |ressource|
            devoir.add_ressource( Ressource.create(  name: ressource['name'],
                                                     hash: ressource['hash'] ) )
          end if params[:ressources]

          devoir.date_modification = Time.now
          devoir.save

          # FIXME: fuite d'info sur :devoir_todo_items
          devoir.to_json include: Devoir.associations
        end
      end

      desc 'marque un devoir comme fait'
      params {
        requires :id
      }
      put '/:id/fait' do
        error!( '401 Unauthorized', 401 ) unless user.is? 'ELV'

        devoir = Devoir[ params[:id] ]
        devoir.fait_par?( user.uid ) ? devoir.a_faire_par!( user.uid ) : devoir.fait_par!( user.uid )

        # FIXME: fuite d'info sur :devoir_todo_items
        devoir.to_json include: Devoir.associations
      end

      desc 'détruit un devoir'
      params {
        requires :id
      }
      delete '/:id' do
        error!( '401 Unauthorized', 401 ) unless user.is? 'ENS'

        devoir = Devoir[ params[:id] ]

        devoir.update( deleted: true, date_modification: Time.now )
        devoir.save

        # FIXME: fuite d'info sur :devoir_todo_items
        devoir.to_json include: Devoir.associations
      end
    end
  end
end
