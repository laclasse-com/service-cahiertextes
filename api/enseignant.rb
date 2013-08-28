# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class EnseignantAPI < Grape::API
    format :json

    resource :enseignant do

      resource :emploi_du_temps do
        desc 'contenu combiné des cahiers de textes concernant l\'élève durant l\'intervalle de dates données ou par défaut le jour courant'
        params {
          optional :debut, type: Time
          optional :fin, type: Time
        }
        get do
          # TODO
        end
      end

      resource :cahier_de_textes do
        desc 'contenu combiné des cahiers de textes concernant l\'enseignant durant l\'intervalle de dates données ou par défaut le jour courant'
        params {
          optional :debut, type: Time
          optional :fin, type: Time
        }
        get do
          #TODO: get this from actual (Enseignant) user
          regroupements_ids = [ 1, 2, 3, 4, 5, 12 ]

          regroupements_ids.map {
            |regroupement_id|
            CahierDeTextes[ regroupement_id: regroupement_id ].content( params[:debut] ? params[:debut] : Time.now,
                                                                        params[:fin] ? params[:fin] : Time.now )
          }.to_json
        end
      end

    end

  end
end
