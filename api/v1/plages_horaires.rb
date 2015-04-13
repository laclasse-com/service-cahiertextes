# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    class PlagesHorairesAPI < Grape::API
      desc 'renvoi toutes les plages horaires'
      get '/' do
        PlageHoraire.all
      end

      desc 'renvoi une plage horaire'
      params do
        requires :id
      end
      get '/:id' do
        PlageHoraire[ params[:id] ]
      end
    end
  end
end
