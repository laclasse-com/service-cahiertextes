# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    class CahiersDeTextesAPI < Grape::API
      desc 'renvoi le cahier de textes d\'un regroupement'
      params {
        requires :regroupement_id
      }
      get '/regroupement/:regroupement_id' do
        CahierDeTextes.where( regroupement_id: params[:regroupement_id] ).to_json include: CahierDeTextes.associations
      end
    end
  end
end
