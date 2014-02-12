# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class PlagesHorairesAPI < Grape::API

    desc 'renvoi toutes les plages horaires'
    get '/' do
      PlageHoraire.all
    end

    desc 'renvoi une plage horaire'
    params {
      requires :id
    }
    get '/:id' do
      PlageHoraire[ params[:id] ]
    end

  end
end
