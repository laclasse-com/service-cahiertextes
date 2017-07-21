# -*- coding: utf-8 -*-

module CahierDeTextesApp
  class EmploisDuTempsAPI < Grape::API
    desc 'emploi du temps de l\'utilisateur durant l\'intervalle de dates donné'
    params do
      requires :debut, type: Date
      requires :fin, type: Date

      optional :uid
    end
    get  do
      cache_control :no_cache

      DataManagement::EmploiDuTemps.get( Date.parse( params[:debut].iso8601 ),
                                         Date.parse( params[:fin].iso8601 ),
                                         user_regroupements_ids( params[:uid] ),
                                         user_active_profile['type'] == 'ELV' ? user['id'] : nil )
    end
  end
end
