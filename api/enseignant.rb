# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class EnseignantAPI < Grape::API
    format :json

    resource :enseignant do

      get '/ping' do
        { ping: "pong" }
      end

    end

  end
end
