# frozen_string_literal: true

module Routes
    module Api
        module ResourceTypes
            def self.registered( app )
                app.get '/api/resource_types/?' do
                    ResourceType.naked.all.to_json
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
                    param 'resource_types', Array, required: true
                    # [{ 'label', String, required: true
                    #    'description', String }]
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    result = params['resource_types'].map do |resource_type|
                        resource_type = JSON.parse( resource_type ) if resource_type.is_a?( String )

                        new_resource_type = ResourceType[ label: params['label'] ]
                        halt( 403, "ResourceType #{resource_type['label']} existant" ) unless new_resource_type.nil?

                        new_resource_type = ResourceType.create( label: resource_type['label'] )
                        new_resource_type.update( description: resource_type['description'] ) if resource_type.key?( 'description' )

                        new_resource_type.to_hash
                    end

                    json( result )
                end

                app.put '/api/resource_types/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'label', String
                    param 'description', String

                    any_of 'label', 'description'
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

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

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    resource_type = ResourceType[ params['id'] ]
                    halt( 404, "ResourceType #{params['id']} inconnu" ) if resource_type.nil?

                    resource_type&.destroy

                    nil
                end
            end
        end
    end
end
