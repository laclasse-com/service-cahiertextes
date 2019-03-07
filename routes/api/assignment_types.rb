# frozen_string_literal: true

module Routes
    module Api
        module AssignmentTypes
            def self.registered( app )
                app.get '/api/assignment_types/?' do
                    AssignmentType.naked.all.to_json
                end

                app.get '/api/assignment_types/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    assignment_type = AssignmentType[ params['id'] ]
                    halt( 404, "AssignmentType #{params['id']} inconnu" ) if assignment_type.nil?

                    json( assignment_type.to_hash )
                end

                app.post '/api/assignment_types/?' do
                    # {
                    param 'assignment_types', Array, required: true
                    # [{ 'label', String, required: true
                    #    'description', String }]
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    result = params['assignment_types'].map do |assignment_type|
                        assignment_type = JSON.parse( assignment_type ) if assignment_type.is_a?( String )

                        new_assignment_type = AssignmentType[ label: assignment_type['label'] ]
                        halt( 403, "AssignmentType #{assignment_type['label']} existant" ) unless new_assignment_type.nil?

                        new_assignment_type = AssignmentType.create( label: assignment_type['label'] )
                        new_assignment_type.update( description: assignment_type['description'] ) if assignment_type.key?( 'description' )

                        new_assignment_type.to_hash
                    end

                    json( result )
                end

                app.put '/api/assignment_types/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'label', String
                    param 'description', String

                    any_of 'label', 'description'
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    assignment_type = AssignmentType[ params['id'] ]
                    halt( 404, "AssignmentType #{params['id']} inconnu" ) if assignment_type.nil?

                    assignment_type.update( label: params['label'] ) if params.key?( 'label' )
                    assignment_type.update( description: params['description'] ) if params.key?( 'description' )

                    json( assignment_type.to_hash )
                end

                app.delete '/api/assignment_types/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    assignment_type = AssignmentType[ params['id'] ]
                    halt( 404, "AssignmentType #{params['id']} inconnu" ) if assignment_type.nil?

                    assignment_type&.destroy

                    nil
                end
            end
        end
    end
end
