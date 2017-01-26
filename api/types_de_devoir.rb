# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class TypesDeDevoirAPI < Grape::API
    desc 'renvoi tous les types de devoirs'
    get '/' do
      TypeDevoir.all
    end

    desc 'renvoi un type de devoir'
    params do
      requires :id
    end
    get '/:id' do
      TypeDevoir[ params[:id] ]
    end
  end
end
