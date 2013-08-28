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
        # GET http://localhost:9292/etablissement/plage_horaire/3
        desc 'statistiques de toutes les classes'
        get do
          PlageHoraire[label: "18"]  # == .filter().first
        end
      end

    end

  end
end
