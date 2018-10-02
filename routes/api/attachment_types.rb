# frozen_string_literal: true

module Routes
    module Api
        module AttachmentTypes
            def self.registered( app )
                app.get '/api/attachment_types/?' do
                    AttachmentType.all.map(&:to_hash).to_json
                end

                app.get '/api/attachment_types/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    attachment_type = AttachmentType[ params['id'] ]
                    halt( 404, "AttachmentType #{params['id']} inconnu" ) if attachment_type.nil?

                    json( attachment_type.to_hash )
                end
            end
        end
    end
end
