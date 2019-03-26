# frozen_string_literal: true

module Routes
    module Api
        module Resources
            def self.registered( app )
                app.post '/api/resources/?' do
                    # {
                    param 'resources', Array, required: true
                    # }

                    first_pass = params['resources'].map do |resource|
                        resource = JSON.parse( resource ) if resource.is_a?( String )

                        halt( 401 ) unless user_is_x_in_structure_s?( %w[ ADM ], resource['structure_id'] )

                        resource
                    end
                    result = first_pass.map do |resource|
                        new_resource = DataManagement::Accessors.create_or_get( Resource,
                                                                                author_id: get_ctxt_user( user['id'] ).id,
                                                                                structure_id: resource['structure_id'],
                                                                                label: resource['label'],
                                                                                type: resource['type'] )

                        new_resource.name = resource['name']
                        new_resource.import_id = resource['import_id'] if resource.key?( 'import_id' )

                        new_resource.save

                        new_resource.to_hash
                    end

                    json( result )
                end

                app.put '/api/resources/:id/?' do
                    # {
                    param 'id', Integer, require: true
                    param 'structure_id', String, required: true
                    param 'name', String, required: true
                    param 'label', String, required: true
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_x_in_structure_s?( %w[ ADM ], params['structure_id'] )

                    resource = Resource[ params['id'] ]
                    halt( 404, "Resource #{params['id']} inconnue" ) if resource.nil?

                    resource.structure_id = params['structure_id']
                    resource.label = params['label']
                    resource.name = params['name']
                    resource.save

                    json( resource )
                end

                app.get '/api/resources/?' do
                    # {
                    param 'structure_id', String
                    param 'label', String
                    param 'name', String
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_x_in_structure_s?( %w[ ADM ], params['structure_id'] )

                    query = Resource
                    query = query.where( structure_id: params['structure_id'] ) if params.key?( 'structure_id' )
                    query = query.where( label: params['label'] ) if params.key?( 'label' )
                    query = query.where( name: params['name'] ) if params.key?( 'name' )

                    json( query.naked.all )
                end

                app.get '/api/resources/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    resource = Resource[ params['id'] ]
                    halt( 404, "Resource #{params['id']} inconnue" ) if resource.nil?

                    json( resource )
                end

                app.delete '/api/resources/:id/?' do
                    # {
                    param 'id', Integer, require: true
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_x_in_structure_s?( %w[ ADM ], params['structure_id'] )

                    resource = Resource[ params['id'] ]
                    halt( 404, "Resource #{params['id']} inconnue" ) if resource.nil?

                    resource&.destroy

                    nil
                end
            end
        end
    end
end
