module Routes
    module Api
        module UsersAPI
            def self.registered( app )
                app.get '/api/users/current/?' do
                    user_ctxt.to_json
                end
            end
        end
    end
end
