# frozen_string_literal: true

module Routes
    module Api
        module Matchables
            def self.registered( app )
                app.get '/api/matchables/:structure_id/?' do
                    # {
                    param 'structure_id', String, required: true
                    # }

                    json( Matchable.where( structure_id: params['structure_id'] ).all )
                end

                app.get '/api/matchables/:structure_id/:hash_item/?' do
                    # {
                    param 'structure_id', String, required: true
                    param 'hash_item', String, required: true
                    # }

                    fi = Matchable[ structure_id: params['structure_id'],
                                    hash_item: params['hash_item'] ]
                    halt( 404 ) if fi.nil?

                    json( fi.to_hash )
                end

                app.post '/api/matchables/:structure_id/?' do
                    # {
                    param 'structure_id', String, required: true
                    param 'matchables', Array, required: true
                    # [ { 'hash_item', String, required: true
                    #  'known_id', String, required: true } ]
                    # }

                    halt( 401 ) unless user_is_x_in_structure_s?( %w[ ADM ], params['structure_id'] )

                    result = params['matchables'].map do |matchable|
                        matchable = JSON.parse( matchable ) if matchable.is_a?( String )

                        fi = Matchable[ structure_id: params['structure_id'], hash_item: matchable['hash_item'] ]
                        if fi.nil?
                            fi = Matchable.create( structure_id: params['structure_id'],
                                                   hash_item: matchable['hash_item'],
                                                   known_id: matchable['known_id'] )
                        else
                            fi.update( known_id: matchable['known_id'] )
                        end

                        fi.save

                        fi.to_hash
                    end

                    json( result )
                end

                app.delete '/api/matchables/:structure_id/:hash_item/?' do
                    # {
                    param 'structure_id', String, required: true
                    param 'hash_item', String, required: true
                    # }
                    halt( 401 ) unless user_is_x_in_structure_s?( %w[ ADM ], params['structure_id'] )

                    fi = Matchable[ structure_id: params['structure_id'],
                                    hash_item: params['hash_item'] ]
                    fi&.destroy

                    Matchable[ structure_id: params['structure_id'],
                               hash_item: params['hash_item'] ]
                end
            end
        end
    end
end
