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

                app.post '/api/resource_types/?' do
                    # {
                    param 'label', String, required: true
                    param 'description', String
                    # }

                    user_needs_to_be( %w[TECH] )

                    resource_type = ResourceType[ label: params['label'] ]
                    halt( 403, "ResourceType #{params['label']} existant" ) unless resource_type.nil?

                    resource_type = ResourceType.create( label: params['label'] )
                    resource_type.update( description: params['description'] ) if params.key?( 'description' )

                    json( resource_type.to_hash )
                end

                app.put '/api/resource_types/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'label', String
                    param 'description', String

                    any_of 'label', 'description'
                    # }

                    user_needs_to_be( %w[TECH] )

                    resource_type = ResourceType[ params['id'] ]
                    halt( 404, "ResourceType #{params['id']} inconnu" ) if resource_type.nil?

                    resource_type.update( label: params['label'] ) if params.key?( 'label' )
                    resource_type.update( description: params['description'] ) if params.key?( 'description' )

                    json( resource_type.to_hash )
                end

                app.delete '/api/resource_types/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    user_needs_to_be( %w[TECH] )

                    resource_type = ResourceType[ params['id'] ]
                    halt( 404, "ResourceType #{params['id']} inconnu" ) if resource_type.nil?

                    resource_type&.destroy

                    nil
                end
            end
        end
    end
end
