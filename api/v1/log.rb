# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    class LogAPI < Grape::API
      desc 'log entry'
      params do
        requires :uid, type: String
        requires :uai, type: String
        requires :timestamp
        requires :url, type: String
        optional :comment, type: String
      end
      post do
        params[:ip] = env[ 'HTTP_X_FORWARDED_FOR' ]
        AnnuaireWrapper::Log.add( params )
      end
    end
  end
end
