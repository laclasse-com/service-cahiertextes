# frozen_string_literal: true

module Routes
    module Api
        module Resources
            def self.registered( app )
                app.post '/api/resources/?' do
                    # {
                    param 'resources', Array, required: true
                    # }

                    user_id = get_ctxt_user( user['id'] ).id

                    first_pass = params['resources'].map do |resource|
                        resource = JSON.parse( resource ) if resource.is_a?( String )

                        halt( 401 ) unless resource['author_id'].to_i == user_id
                        halt( 401 ) unless user_is_x_in_structure_s?( %w[ ADM ], resource['structure_id'] )

                        resource
                    end
                    result = first_pass.map do |resource|
                        new_resource = DataManagement::Accessors.create_or_get( Resource,
                                                                                author_id: resource['author_id'],
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

                    halt( 401 ) unless user_is_x_in_structure_s?( %w[ ADM ], params['structure_id'] )

                    resource = Resource[ params['id'] ]
                    halt( 404 ) if resource.nil?

                    resource.structure_id = params['structure_id']
                    resource.label = params['label']
                    resource.name = params['name']
                    resource.save

                    json( resource )
                end

                app.get '/api/resources/?' do
                    # {
                    param 'author_id', Integer
                    param 'structures_ids', Array
                    param 'label', String
                    param 'name', String
                    # }

                    user_id = get_ctxt_user( user['id'] ).id

                    halt( 401 ) unless user_is_x_in_structure_s?( %w[ ADM ], params['structure_id'] )

                    query = Resource
                    if params.key?( 'author_id' )
                        halt( 401 ) unless params['author_id'] == user_id
                        query = query.where( author_id: params['author_id'] )
                    end
                    query = query.where( structure_id: params['structures_ids'] ) if params.key?( 'structures_ids' )
                    query = query.where( label: params['label'] ) if params.key?( 'label' )
                    query = query.where( name: params['name'] ) if params.key?( 'name' )

                    json( query.naked.all )
                end

                app.get '/api/resources/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    resource = Resource[ params['id'] ]
                    halt( 404 ) if resource.nil?

                    json( resource )
                end

                app.delete '/api/resources/:id/?' do
                    # {
                    param 'id', Integer, require: true
                    # }

                    halt( 401 ) unless user_is_x_in_structure_s?( %w[ ADM ], params['structure_id'] )

                    resource = Resource[ params['id'] ]
                    halt( 404 ) if resource.nil?

                    resource&.destroy

                    Resource[ params['id'] ]
                end
            end
        end
    end
end
