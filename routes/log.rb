# -*- coding: utf-8 -*-

module CahierDeTextesApp
  module Routes
    module Log
      def self.registered( app )
        #
        # Tell Annuaire to log this
        #
        app.post "#{APP_PATH}/log/?" do
          # param :uid, String, required: true
          # param :uai, String, required: true
          # param :timestamp, BigNum, required: true
          # param :action, String, required: true
          # param :url, String, required: true
          # param :comment, String
          
          log_entry = JSON.parse( request.body.read )
          log_entry['ip'] = request.env[ 'HTTP_X_FORWARDED_FOR' ]
          AnnuaireWrapper::Log.add( log_entry )
        end
      end
    end
  end
end
