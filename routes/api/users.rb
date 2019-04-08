# frozen_string_literal: true

require_relative '../../lib/data_management/accessors'

module Routes
    module Api
        module UsersAPI
            def self.registered( app )
                app.get '/api/users/:uid/?' do
                    param 'uid', String, required: true

                    halt( 401 ) unless params['uid'] == session['user']

                    json( get_ctxt_user( params['uid'] ).to_hash )
                end

                app.put '/api/users/:uid/?' do
                    param 'uid', String, required: true
                    param 'parameters', String, required: true

                    halt( 401 ) unless params['uid'] == session['user']

                    ctxt_user = DataManagement::Accessors.create_or_get( User,
                                                                         uid: params['uid'] )

                    ctxt_user.update( parameters: params['parameters'] )
                    ctxt_user.save

                    json( ctxt_user.to_hash )
                end
            end
        end
    end
end
