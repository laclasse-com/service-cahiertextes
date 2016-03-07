# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    class PlagesHorairesAPI < Grape::API
      desc 'renvoi toutes les plages horaires'
      get '/' do
        PlageHoraire.all
      end

      desc 'return the plage horaire'
      params do
        requires :id
      end
      get '/:id' do
        ph = PlageHoraire[ params[:id] ]
        error!( "Plage horaire #{params[:id]} inconnu", 404 ) if ph.nil?

        ph
      end

      desc 'create a plage horaire'
      params do
        requires :label
        requires :debut
        requires :fin
      end
      post '/' do
        ph = DataManagement::Accessors.create_or_get( PlageHoraire,
                                                      label: params[:label] )
        ph.update( debut: params[:debut],
                   fin: params[:fin] )
        ph.save

        ph
      end

      desc 'update the plage horaire'
      params do
        requires :id

        optional :label
        optional :debut
        optional :fin
      end
      put '/:id' do
        ph = PlageHoraire[ params[:id] ]
        error!( "Plage horaire #{params[:id]} inconnu", 404 ) if ph.nil?

        ph.label = params[:label] if params.key? :label
        ph.debut = params[:debut] if params.key? :debut
        ph.fin = params[:fin] if params.key? :fin
        ph.save

        ph
      end

      desc 'delete the plage horaire'
      params do
        requires :id
      end
      delete '/:id' do
        ph = PlageHoraire[ params[:id] ]
        error!( "Plage horaire #{params[:id]} inconnu", 404 ) if ph.nil?

        ph.destroy
      end
    end
  end
end
