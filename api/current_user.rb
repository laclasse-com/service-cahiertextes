# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class CurrentUserAPI < Grape::API

    desc 'renvoi les infos de l\'utilisateur indentifié'
    get '/' do
      env['rack.session'][:current_user]
    end

  end
end
