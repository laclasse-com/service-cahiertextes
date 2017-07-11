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
                                         params[:uid] )
    end

    # format :txt
    # desc 'emploi du temps de l\'utilisateur durant l\'intervalle de dates donné au format ical'
    # params do
    #   requires :debut, type: Date
    #   requires :fin, type: Date

    #   optional :uid
    # end
    # get '/ics' do
    #   content_type 'text/calendar'
    #   header 'Content-Disposition', "filename*=UTF-8''emploi_du_temps_#{params.key?(:uid) ? params[:uid] : user['id']}.ics"

    #   DataManagement::EmploiDuTemps.ical( Date.parse( params[:debut].iso8601 ),
    #                                       Date.parse( params[:fin].iso8601 ),
    #                                       user_regroupements_ids( params[:uid] ),
    #                                       user[:user_detailed]['profil_actif']['profil_id'],
    #                                       params[:uid] )
    # end
  end
end
