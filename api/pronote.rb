# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class ProNote < Grape::API
    format :json

    resource :pronote do
      
      get '/ping' do
        { ping: "pong" }
      end

      # POST
      desc "Upload an image."
      post 'upload_xml' do
        {
          filename: params[:xml_file][:filename],
          size: params[:xml_file][:tempfile].size
        }
      end

    end

  end
end
