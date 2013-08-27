# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class Eleve < Grape::API
    format :json

    resource :eleve do

      get '/ping' do
        { ping: "pong" }
      end

    end

  end
end
