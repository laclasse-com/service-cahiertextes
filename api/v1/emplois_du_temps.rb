# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    class EmploisDuTempsAPI < Grape::API
      # desc 'emploi du temps de l\'utilisateur durant l\'intervalle de dates donné'
      # params {
      #   requires :debut, type: Date
      #   requires :fin, type: Date

      #   optional :uid
      # }
      # get '/du/:debut/au/:fin' do
      #   LOGGER.debug 'Params in url'
      #   if params[:uid].nil?
      #     LOGGER.debug 'Pas d\'uid fourni'
      #     emploi_du_temps( Date.parse( params[:debut].iso8601 ),
      #                      Date.parse( params[:fin].iso8601 ),
      #                      user.regroupements_ids )
      #   else
      #     LOGGER.debug "uid fourni : #{params[:uid]}"

      #       emploi_du_temps( Date.parse( params[:debut].iso8601 ),
      #                        Date.parse( params[:fin].iso8601 ),
      #                        user.regroupements_ids( params[:uid] ),
      #                        params[:uid] )
      #   end
      # end

      desc 'emploi du temps de l\'utilisateur durant l\'intervalle de dates donné'
      params {
        requires :debut, type: Date
        requires :fin, type: Date

        optional :uid
      }
      get  do
        emploi_du_temps( Date.parse( params[:debut].iso8601 ),
                         Date.parse( params[:fin].iso8601 ),
                         user.regroupements_ids( params[:uid] ),
                         params[:uid] )
      end
    end
  end
end
