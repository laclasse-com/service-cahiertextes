# frozen_string_literal: true

module Routes
    module Api
        module Trails
            def self.registered( app )
                app.get '/api/trails/?' do
                    query = Trail.where( Sequel[{author_id: get_ctxt_user( user['id']).id }] | Sequel[{private: false}] )

                    json( query.naked.all )
                end

                app.get '/api/trails/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    trail = Trail[ params['id'] ]
                    halt( 404 ) if trail.nil?
                    halt( 401 ) if trail.private && trail.author_id != get_ctxt_user( user['id']).id

                    json( trail.to_hash )
                end

                app.post '/api/trails/?' do
                    # {
                    param 'trails', Array, required: true
                    # }

                    halt( 401 ) unless user_is_x_in_structure_s?( %w[ENS DOC ADM] ) || user_is_super_admin?
                    cuid = get_ctxt_user( user['id']).id

                    first_pass = params['trails'].map do |trail|
                        trail = JSON.parse( trail ) if trail.is_a?( String )

                        halt( 403 ) unless params['trails'].select { |t| t['label'] == trail['label'] }.count == 1
                        halt( 403 ) unless Trail[ label: trail['label'],
                                                  author_id: cuid ].nil?

                        trail
                    end
                    result = first_pass.map do |trail|
                        new_trail = Trail.create( label: trail['label'],
                                                  private: trail['private'],
                                                  author_id: cuid )

                        new_trail.to_hash
                    end

                    json( result )
                end

                app.put '/api/trails/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'label', String, required: true
                    # }

                    trail = Trail[ params['id'] ]
                    halt( 404 ) if trail.nil?

                    cuid = get_ctxt_user( user['id']).id
                    halt( 401 ) unless trail.author_id == get_ctxt_user( user['id']).id || user_is_super_admin?

                    overlapping_trail = Trail[ label: params['label'],
                                               private: trail['private'],
                                               author_id: cuid ]
                    halt( 403 ) unless overlapping_trail.nil?

                    trail.update( label: params['label'] )

                    json( trail.to_hash )
                end

                app.delete '/api/trails/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    trail = Trail[ params['id'] ]
                    halt( 404 ) if trail.nil?
                    halt( 401 ) unless trail.author_id == get_ctxt_user( user['id']).id || user_is_super_admin?

                    trail&.destroy

                    Trail[ params['id'] ]
                end
            end
        end
    end
end
