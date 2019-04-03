# frozen_string_literal: true

module Routes
    module Api
        module AssignmentDoneMarkers
            def self.registered( app )
                app.post '/api/assignment_done_markers/?' do
                    # {
                    param 'assignment_done_markers', Array, required: true
                    # }

                    # halt( 401 ) unless user_is_x_in_structure_s?( %w[ENS DOC ADM] ) || user_is_super_admin?
                    user_id = get_ctxt_user( user['id']).id

                    first_pass = params['assignment_done_markers'].map do |assignment_done_marker|
                        assignment_done_marker = JSON.parse( assignment_done_marker ) if assignment_done_marker.is_a?( String )

                        halt( 401 ) unless assignment_done_marker['author_id'].to_i == user_id
                        halt( 403 ) unless AssignmentDoneMarker[ content_id: assignment_done_marker['content_id'],
                                                                 author_id: user_id ].nil?

                        assignment_done_marker
                    end
                    result = first_pass.map do |assignment_done_marker|
                        new_assignment_done_marker = AssignmentDoneMarker.create( content_id: assignment_done_marker['content_id'].to_i,
                                                                                  rtime: DateTime.now,
                                                                                  author_id: assignment_done_marker['author_id'].to_i )

                        new_assignment_done_marker.to_hash
                    end

                    json( result )
                end

                app.get '/api/assignment_done_markers/?' do
                    # {
                    param 'author_id', Integer, required: true
                    # }

                    halt( 401 ) if params['author_id'] != get_ctxt_user( user['id']).id

                    query = AssignmentDoneMarker.where( author_id: params['author_id'] )

                    json( query.naked.all )
                end

                app.get '/api/assignment_done_markers/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    assignment_done_marker = AssignmentDoneMarker[ id: params['id'] ]
                    halt( 404 ) if assignment_done_marker.nil?
                    halt( 401 ) if assignment_done_marker.author_id != get_ctxt_user( user['id']).id

                    json( assignment_done_marker.to_hash )
                end

                app.delete '/api/assignment_done_markers/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    assignment_done_marker = AssignmentDoneMarker[ params['id'] ]
                    halt( 404 ) if assignment_done_marker.nil?
                    halt( 401 ) unless assignment_done_marker.author_id == get_ctxt_user( user['id']).id || user_is_super_admin?

                    assignment_done_marker&.destroy

                    AssignmentDoneMarker[ params['id'] ]
                end
            end
        end
    end
end
