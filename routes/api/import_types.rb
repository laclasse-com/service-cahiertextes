# frozen_string_literal: true

module Routes
    module Api
        module ImportTypes
            def self.registered( app )
                app.get '/api/import_types/?' do
                    ImportType.all.map(&:to_hash).to_json
                end

                app.get '/api/import_types/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    import_type = ImportType[ params['id'] ]
                    halt( 404, "ImportType #{params['id']} inconnu" ) if import_type.nil?

                    json( import_type.to_hash )
                end

                app.post '/api/import_types/?' do
                    # {
                    param 'label', String, required: true
                    param 'description', String
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    import_type = ImportType[ label: params['label'] ]
                    halt( 403, "ImportType #{params['label']} existant" ) unless import_type.nil?

                    import_type = ImportType.create( label: params['label'] )
                    import_type.update( description: params['description'] ) if params.key?( 'description' )

                    json( import_type.to_hash )
                end

                app.put '/api/import_types/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'label', String
                    param 'description', String

                    any_of 'label', 'description'
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    import_type = ImportType[ params['id'] ]
                    halt( 404, "ImportType #{params['id']} inconnu" ) if import_type.nil?

                    import_type.update( label: params['label'] ) if params.key?( 'label' )
                    import_type.update( description: params['description'] ) if params.key?( 'description' )

                    json( import_type.to_hash )
                end

                app.delete '/api/import_types/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    import_type = ImportType[ params['id'] ]
                    halt( 404, "ImportType #{params['id']} inconnu" ) if import_type.nil?

                    import_type&.destroy

                    nil
                end
            end
        end
    end
end
