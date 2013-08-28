# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class PrincipalAPI < Grape::API
    format :json

    resource :principal do

      resource :ping do
        get do
          { ping: "pong" }
        end
      end

      resource :classes do
        desc 'statistiques de toutes les classes'
        get do
          PlageHoraire[label: "18"]  # == .filter().first
        end
      end

    end

  end
end
