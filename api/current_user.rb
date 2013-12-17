# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class CurrentUserAPI < Grape::API

    desc 'renvoi les infos de l\'utilisateur identifié'
    get  do
      user
    end

  end
end
