# frozen_string_literal: true

module Routes
    module Api
        module AssignmentTypes
            def self.registered( app )
                app.get '/api/assignment_types/?' do
                    AssignmentType.all.map(&:to_hash).to_json
                end

                app.get '/api/assignment_types/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    assignment_type = AssignmentType[ params['id'] ]
                    halt( 404, "AssignmentType #{params['id']} inconnu" ) if assignment_type.nil?

                    json( assignment_type.to_hash )
                end
            end
        end
    end
end
