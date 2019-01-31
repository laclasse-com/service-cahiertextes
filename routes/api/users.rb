# frozen_string_literal: true

require_relative '../../lib/data_management/accessors'

module Routes
    module Api
        module UsersAPI
            def self.registered( app )
                app.get '/api/users/current/parametres/?' do
                    json( get_ctxt_user( session['user'] ).to_hash )
                end

                app.put '/api/users/current/parametres/?' do
                    param 'parameters', String, required: true

                    parameters = DataManagement::Accessors.create_or_get( User,
                                                                          uid: session['user'] )

                    parameters.update( parameters: params['parameters'] )
                    parameters.save

                    json( parameters.to_hash )
                end
            end
        end
    end
end
