# -*- coding: utf-8 -*-

require_relative '../lib/data_management'

module CahierDeTextesApp
  class UsersAPI < Grape::API
    desc 'renvoi les infos de l\'utilisateur identifié'
    get '/current' do
      user_ctxt
    end

    desc 'met à jour les paramètres utilisateurs'
    params do
      requires :parametres, type: String
    end
    put '/current/parametres' do
      parametres = UserParameters.where( uid: user['id'] ).first

      parametres.update( parameters: params[:parametres] )
      parametres.save

      user_ctxt
    end
  end
end
