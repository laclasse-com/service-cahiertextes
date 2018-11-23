# frozen_string_literal: true

module Routes
    module Api
        module Resources
            def self.registered( app )
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

                app.post '/api/resources/?' do
                    # {
                    param 'structure_id', String
                    param 'label', String
                    param 'name', String
                    param 'import_id', Integer, required: false
                    param 'resource_type_id', Integer, required: false

                    param 'resources', Array

                    one_of 'label', 'resources'
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_x_in_structure_s?( %w[ ADM ], params['structure_id'] )

                    single = !params.key?( 'resources' )
                    resources = if single
                                    [ { "structure_id" => params['structure_id'],
                                        "label" => params['label'],
                                        "name" => params['name'],
                                        "resource_type_id" => params['resource_type_id'],
                                        "import_id" => params['import_id'] } ]
                                else
                                    params['resources']
                                end

                    result = resources.map do |resource|
                        new_resource = DataManagement::Accessors.create_or_get( Resource,
                                                                                structure_id: resource['structure_id'],
                                                                                label: resource['label'] )

                        new_resource.name = resource['name']
                        new_resource.save

                        import = Import[ id: resource['import_id'] ]
                        new_resource.add_import( import ) unless import.nil?

                        rt = ResourceType[ id: resource['resource_type_id'] ]
                        new_resource.add_resource_type( rt ) unless rt.nil?

                        new_resource.to_hash
                    end

                    result = result.first if single

                    json( result )
                end

                app.put '/api/resources/:id/?' do
                    # {
                    param 'id', Integer, require: true
                    param 'structure_id', String, required: true
                    param 'name', String, required: true
                    param 'label', String, required: true
                    # }

                    resource = Resource[ params['id'] ]

                    halt( 404, "Resource #{params['id']} inconnue" ) if resource.nil?

                    halt( 401, '401 Unauthorized' ) unless user_is_x_in_structure_s?( %w[ ADM ], params['structure_id'] )

                    resource.structure_id = params['structure_id']

                    resource.label = params['label']
                    resource.name = params['name']
                    resource.save

                    json( resource )
                end

                app.delete '/api/resources/:id/?' do
                    # {
                    param 'id', Integer, require: true
                    # }

                    resource = Resource[ params['id'] ]

                    halt( 404, "Resource #{params['id']} inconnue" ) if resource.nil?

                    halt( 401, '401 Unauthorized' ) unless user_is_x_in_structure_s?( %w[ ADM ], params['structure_id'] )

                    resource&.destroy

                    nil
                end
            end
        end
    end
end
