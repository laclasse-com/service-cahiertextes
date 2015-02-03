# -*- coding: utf-8 -*-

require_relative '../../lib/annuaire_wrapper'

module CahierDeTextesAPI
  module V1
    class EmploisDuTempsAPI < Grape::API
      desc 'emploi du temps de l\'utilisateur durant l\'intervalle de dates donné'
      params {
        requires :debut, type: Date
        requires :fin, type: Date

        optional :uai
        optional :uid
      }
      get '/du/:debut/au/:fin' do
        emploi_du_temps( user, Date.parse( params[:debut].iso8601 ), Date.parse( params[:fin].iso8601 ), params[:uai], params[:uid] )
      end

      desc 'emploi du temps de l\'utilisateur durant l\'intervalle de dates donné'
      params {
        requires :start, type: Date
        requires :end, type: Date

        optional :uai
        optional :uid
      }
      get  do
        emploi_du_temps( user, Date.parse( params[:start].iso8601 ), Date.parse( params[:end].iso8601 ), params[:uai], params[:uid] )
      end
    end
  end
end
