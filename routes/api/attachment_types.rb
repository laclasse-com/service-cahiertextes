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
                    param 'attachment_types', Array, required: true
                    # [{ 'label', String, required: true
                    #  'description', String }]
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    result = params['attachment_types'].map do |new_attachment_type|
                        attachment_type = AttachmentType[ label: new_attachment_type['label'] ]
                        halt( 403, "AttachmentType #{new_attachment_type['label']} existant" ) unless attachment_type.nil?

                        attachment_type = AttachmentType.create( label: new_attachment_type['label'] )
                        attachment_type.update( description: new_attachment_type['description'] ) if new_attachment_type.key?( 'description' )

                        attachment_type.to_hash
                    end

                    json( result )
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
