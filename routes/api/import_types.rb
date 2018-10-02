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
            end
        end
    end
end
