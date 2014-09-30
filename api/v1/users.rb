# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    class UsersAPI < Grape::API
      desc 'renvoi les infos de l\'utilisateur identifié'
      get '/current' do
        user.full( env )
      end

      desc 'met à jour les paramètres utilisateurs'
      params {
        requires :parametres, type: String
      }
      put '/current/user_parameters/?' do
        parametres = UserParameters.where( uid: utilisateur[ 'uid' ] ).first

        parametres.update( parameters: params[:parametres] )
        parametres.save

        user.full( env )
      end

      desc 'efface toute trace de l\'utilisateur identifié'
      delete '/:id' do
        # TODO
        STDERR.puts "Deleteing all traces of #{params[:id]}"
      end

      desc 'Merge les données de l\'utilisateur source_id vers l\'utilisateur target_id'
      put '/:target_id/merge/:source_id' do
        # TODO
        STDERR.puts "Merging all data of #{params[:source_id]} into #{params[:target_id]}"
      end
    end
  end
end
