# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class EleveAPI < Grape::API
    format :json

    resource :eleve do

      get '/ping' do
        { ping: "pong" }
      end

    end

  end
end
