# frozen_string_literal: true

module Routes
    module Api
        module ResourceTypes
            def self.registered( app )
                app.get '/api/resource_types/?' do
                    ResourceType.all.map(&:to_hash).to_json
                end

                app.get '/api/resource_types/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    resource_type = ResourceType[ params['id'] ]
                    halt( 404, "ResourceType #{params['id']} inconnu" ) if resource_type.nil?

                    json( resource_type.to_hash )
                end
            end
        end
    end
end
