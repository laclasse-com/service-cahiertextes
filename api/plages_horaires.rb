# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class PlagesHorairesAPI < Grape::API

    desc 'renvoi toutes les plages horaires'
    get '/' do
      PlageHoraire.all.map {
        |ph|

        { id: ph.id,
          label: ph.label,
          debut: ph.debut.iso8601,
          fin: ph.fin.iso8601 }
      }
    end

    desc 'renvoi une plage horaire'
    params {
      requires :id
    }
    get '/:id' do
       ph = PlageHoraire[ params[:id] ]

       { id: ph.id,
         label: ph.label,
         debut: ph.debut.iso8601,
         fin: ph.fin.iso8601 }
    end

  end
end
