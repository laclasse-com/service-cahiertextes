# -*- coding: utf-8 -*-

module CahierDeTextesApp
  module Routes
    module Api
      module UserParametersAPI
        def self.registered( app )
          app.get '/api/users/current/parametres/?' do
            # param :uid, String, required: true

            parameters = DataManagement::Accessors.create_or_get( UserParameters,
                                                                  uid: params['uid'] )
            parameters.update( date_connexion: Time.now )
            parameters.save

            json( parameters.to_hash )
          end

          app.put '/api/users/current/parametres/?' do
            # param :uid, String, required: true

            request.body.rewind
            body = JSON.parse( request.body.read )

            parameters = DataManagement::Accessors.create_or_get( UserParameters,
                                                                  uid: params['uid'] )

            parameters.update( parameters: body['parameters'] )
            parameters.save

            json( parameters.to_hash )
          end
        end
      end
    end
  end
end
