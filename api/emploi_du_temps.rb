# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class EmploiDuTempsAPI < Grape::API

    desc 'emploi du temps de l\'utilisateur durant l\'intervalle de dates donné'
    params {
      optional :debut, type: Time
      optional :fin, type: Time
    }
    get do
      # TODO
      {}
    end

  end
end
