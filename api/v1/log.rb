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
        Laclasse::CrossApp::Sender.post_request_signed( :service_annuaire_v2_logs, '', params, {} )
      end
    end
  end
end
