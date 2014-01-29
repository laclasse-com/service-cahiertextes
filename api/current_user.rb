# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class CurrentUserAPI < Grape::API

    desc 'renvoi les infos de l\'utilisateur identifié'
    get  do
       utilisateur = env['rack.session'][:current_user]

       utilisateur['classes'] = [] unless utilisateur.has_key? 'classes'

       # FIXME: DEBUG
       p utilisateur
       utilisateur
      # env['rack.session'][:current_user]
    end

  end
end
