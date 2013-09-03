# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class EleveAPI < Grape::API
    format :json

    resource :eleve do

      resource :emploi_du_temps do

        desc 'emploi du temps de l\'élève durant l\'intervalle de dates données ou par défaut le jour courant'
        params {
          optional :debut, type: Time
          optional :fin, type: Time
        }
        get do
          # TODO
          {}
        end

      end

      resource :cahier_de_textes do
        desc 'contenu combiné des cahiers de textes concernant l\'élève durant l\'intervalle de dates données ou par défaut le jour courant'
        params {
          optional :debut, type: Time
          optional :fin, type: Time
        }
        get do
          # TODO: get this from actual (Élève) user
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

        # FIXME: copypasta de l'api enseignant
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

      end

      resource :devoir do

        # FIXME: copypasta de l'api enseignant

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

            hash
          end
        end

        desc 'permet de noter un devoir comme fait/à faire'
        params {
          requires :id
        }
        put '/:id' do
          # FIXME: get real (Élève) user
          eleve_id = 1

          # Devoir[:id].fait_par?( user_id ) && Devoir[:id].plus_fait_par( user_id ) ||
          Devoir[:id].fait_par( eleve_id )
        end
      end

    end

  end
end
