# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    class EmploisDuTempsAPI < Grape::API
      desc 'emploi du temps de l\'utilisateur durant l\'intervalle de dates donné'
      params {
        requires :debut, type: Date
        requires :fin, type: Date

        optional :uid
      }
      get '/du/:debut/au/:fin' do
        DataManagement::EmploiDuTemps.get( Date.parse( params[:debut].iso8601 ),
                                           Date.parse( params[:fin].iso8601 ),
                                           user_regroupements_ids( params[:uid] ),
                                           params[:uid] )
      end

      desc 'emploi du temps de l\'utilisateur durant l\'intervalle de dates donné'
      params {
        requires :debut, type: Date
        requires :fin, type: Date

        optional :uid
      }
      get  do
        DataManagement::EmploiDuTemps.get( Date.parse( params[:debut].iso8601 ),
                                           Date.parse( params[:fin].iso8601 ),
                                           user_regroupements_ids( params[:uid] ),
                                           params[:uid] )
      end
    end
  end
end
