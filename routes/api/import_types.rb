# frozen_string_literal: true

module Routes
    module Api
        module ImportTypes
            def self.registered( app )
                app.get '/api/import_types/?' do
                    ImportType.naked.all.to_json
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
                    param 'import_types', Array, required: true
                    # [{ 'label', String, required: true
                    #    'description', String }]
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    result = params['import_types'].map do |import_type|
                        import_type = JSON.parse( import_type ) if import_type.is_a?( String )

                        new_import_type = ImportType[ label: import_type['label'] ]
                        halt( 403, "ImportType #{import_type['label']} existant" ) unless new_import_type.nil?

                        new_import_type = ImportType.create( label: import_type['label'] )
                        new_import_type.update( description: import_type['description'] ) if import_type.key?( 'description' )

                        new_import_type.to_hash
                    end

                    json( result )
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
