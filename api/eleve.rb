# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class EleveAPI < Grape::API
    format :json

    resource :eleve do

      resource :cahier_de_textes do
        desc 'contenu combiné des cahiers de textes concernant l\'élève durant l\'intervalle de dates données ou par défaut le jour courant'
        params {
          optional :debut, type: Time
          optional :fin, type: Time
        }
        get do
          #TODO: get this from actual (Élève) user
          regroupements_ids = [ 1, 2, 3, 4, 5, 12 ]

          regroupements_ids.map {
            |regroupement_id|
            CahierDeTextes[ regroupement_id: regroupement_id ].content( params[:debut] ? params[:debut] : Time.now,
                                                                        params[:fin] ? params[:fin] : Time.now )
          }.to_json
        end
      end

      resource :devoir do
        desc 'permet de noter un devoir comme fait/à faire'
        params {
          requires :id
        }
        put '/:id' do
          # FIXME: get real (Élève) user
          user_id = 1

          Devoir[:id].fait_par?( user_id ) && Devoir[:id].plus_fait_par( user_id ) || Devoir[:id].fait_par( user_id )
        end
      end

    end

  end
end
