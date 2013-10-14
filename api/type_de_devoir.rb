# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class TypeDeDevoirAPI < Grape::API

    desc 'renvoi tous les types de devoirs'
    get '/' do
      TypeDevoir.all
    end

    desc 'renvoi un type de devoir'
    params {
      requires :id
    }
    get '/:id' do
      TypeDevoir[ params[:id] ]
    end

  end
end
