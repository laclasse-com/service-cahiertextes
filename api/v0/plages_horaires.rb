# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V0
    class PlagesHorairesAPI < Grape::API

      desc 'renvoi toutes les plages horaires'
      get '/' do
        PlageHoraire.to_json include: PlageHoraire.associations
      end

      desc 'renvoi une plage horaire'
      params {
        requires :id
      }
      get '/:id' do
        PlageHoraire[ params[:id] ].to_json include: PlageHoraire.associations
      end

    end
  end
end
