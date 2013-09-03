# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class EnseignantAPI < Grape::API
    format :json

    resource :enseignant do

      resource :emploi_du_temps do

        desc 'emploi du temps de l\'enseignant durant l\'intervalle de dates données ou par défaut la semaine courante'
        params {
          optional :debut, type: Time
          optional :fin, type: Time
        }
        get do
          # TODO
          {}
        end

      end

      resource :cahiers_de_textes do

        desc 'contenu combiné des cahiers de textes concernant l\'enseignant durant l\'intervalle de dates données ou par défaut le jour courant'
        params {
          optional :debut, type: Time
          optional :fin, type: Time
        }
        get do
          # TODO: get this from actual (Enseignant) user
          regroupements_ids = [ 1, 2, 3, 4, 5, 12 ]

          regroupements_ids.map {
            |regroupement_id|
            cdt = CahierDeTextes[ regroupement_id: regroupement_id ]
            unless cdt.nil?
              CahierDeTextes[ regroupement_id: regroupement_id ].content( params[:debut] ? params[:debut] : Time.now,
                                                                          params[:fin] ? params[:fin] : Time.now )
            end
          }.to_json
        end

      end

      resource :cours do

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

        desc 'renvoi une séquence pédagogique'
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

      resource :devoir do

        desc 'renseigne un devoir'
        params {
          requires :cours_id
          requires :type_devoir_id
          requires :contenu
          requires :date_due, type: Date
          optional :ressources
        }
        post '/:cours_id' do
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
          requires :cours_id
          requires :type_devoir_id
          requires :contenu
          requires :date_due, type: Date
          optional :ressources
        }
        put '/:cours_id' do
          devoir = Devoir.where(cours_id: params[:cours_id]).first
          unless devoir.nil?
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

        desc 'renvoi le détail d\'un devoir'
        params {
          requires :cours_id
        }
        get '/:cours_id' do
          devoir = Devoir.where(cours_id: params[:cours_id]).first
          unless devoir.nil?
            hash = devoir.to_hash
            hash[:ressources] = devoir.ressources

            hash
          end
        end
      end

    end

  end
end
