# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class CahierDeTextesAPI < Grape::API

    desc 'contenu combiné des cahiers de textes concernant l\'utilisateur durant l\'intervalle de dates donné'
    params {
      optional :debut, type: Time
      optional :fin, type: Time
    }
    get  do
      # TODO: prendre en compte debut et fin

      # TODO: get this from actual (Élève) user
      regroupements_ids = CreneauEmploiDuTempsRegroupement.all.sample( 5 ).map {|r| r.regroupement_id}

      regroupements_ids.map {
        |regroupement_id|
        cdt = CahierDeTextes[ regroupement_id: regroupement_id ]
        unless cdt.nil?
          CahierDeTextes[ regroupement_id: regroupement_id ].contenu( params[:debut] ? params[:debut] : Time.now,
                                                                      params[:fin] ? params[:fin] : Time.now )
        end
      }
    end

  end
end
