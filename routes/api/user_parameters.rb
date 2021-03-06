module CahierDeTextesApp
  module Routes
    module Api
      module UserParametersAPI
        def self.registered( app )
          app.get '/api/users/current/parametres/?' do
            parameters = DataManagement::Accessors.create_or_get( UserParameters,
                                                                  uid: session['user'] )
            parameters.update( date_connexion: Time.now )
            parametres.update( parameters: { affichage_types_de_devoir: true, affichage_week_ends: false }.to_json ) if parametres[:parameters].empty?
            parameters.save

            json( parameters.to_hash )
          end

          app.put '/api/users/current/parametres/?' do
            request.body.rewind
            body = JSON.parse( request.body.read )

            parameters = DataManagement::Accessors.create_or_get( UserParameters,
                                                                  uid: session['user'] )

            parameters.update( parameters: body['parameters'] )
            parameters.save

            json( parameters.to_hash )
          end
        end
      end
    end
  end
end
