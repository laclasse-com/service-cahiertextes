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

                app.post '/api/attachment_types/?' do
                    # {
                    param 'label', String, required: true
                    param 'description', String
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    attachment_type = AttachmentType[ label: params['label'] ]
                    halt( 403, "AttachmentType #{params['label']} existant" ) unless attachment_type.nil?

                    attachment_type = AttachmentType.create( label: params['label'] )
                    attachment_type.update( description: params['description'] ) if params.key?( 'description' )

                    json( attachment_type.to_hash )
                end

                app.put '/api/attachment_types/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'label', String
                    param 'description', String

                    any_of 'label', 'description'
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    attachment_type = AttachmentType[ params['id'] ]
                    halt( 404, "AttachmentType #{params['id']} inconnu" ) if attachment_type.nil?

                    attachment_type.update( label: params['label'] ) if params.key?( 'label' )
                    attachment_type.update( description: params['description'] ) if params.key?( 'description' )

                    json( attachment_type.to_hash )
                end

                app.delete '/api/attachment_types/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    attachment_type = AttachmentType[ params['id'] ]
                    halt( 404, "AttachmentType #{params['id']} inconnu" ) if attachment_type.nil?

                    attachment_type&.destroy

                    nil
                end
            end
        end
    end
end
