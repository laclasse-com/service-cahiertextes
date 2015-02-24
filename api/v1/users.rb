# -*- coding: utf-8 -*-

require_relative '../../lib/data_management'

module CahierDeTextesAPI
  module V1
    class UsersAPI < Grape::API
      desc 'renvoi les infos de l\'utilisateur identifié'
      get '/current' do
        user_verbose
      end

      desc 'met à jour les paramètres utilisateurs'
      params {
        requires :parametres, type: String
      }
      put '/current/parametres' do
        parametres = UserParameters.where( uid: user[:uid] ).first

        parametres.update( parameters: params[:parametres] )
        parametres.save

        user_verbose
      end

      desc 'efface toute trace de l\'utilisateur identifié'
      delete '/:uid' do
        user_needs_to_be( [], true )

        DataManagement::User.delete( params[:uid] )
      end

      desc 'Merge les données de l\'utilisateur source_id vers l\'utilisateur target_id'
      put '/:target_uid/merge/:source_uid' do
        user_needs_to_be( [], true )

        DataManagement::User.merge( params[:target_uid], params[:source_uid] )
      end
    end
  end
end
