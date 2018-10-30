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
                    halt( 404, "No match for #{params['hash_item']}" ) if fi.nil?

                    json( fi.to_hash )
                end

                app.post '/api/matchables/:structure_id/?' do
                    # {
                    param 'structure_id', String, required: true
                    param 'hash_item', String, required: true
                    param 'known_id', String, required: true
                    # }

                    fi = Matchable[ structure_id: params['structure_id'], hash_item: params['hash_item'] ]

                    if fi.nil?
                        fi = Matchable.create( structure_id: params['structure_id'],
                                               hash_item: params['hash_item'],
                                               known_id: params['known_id'] )
                    else
                        fi.update( known_id: params['known_id'] )
                    end

                    fi.save

                    json( fi.to_hash )
                end

                app.delete '/api/matchables/:structure_id/:hash_item/?' do
                    # {
                    param 'structure_id', String, required: true
                    param 'hash_item', String, required: true
                    # }

                    fi = Matchable[ structure_id: params['structure_id'],
                                    hash_item: params['hash_item'] ]
                    fi&.destroy

                    nil
                end
            end
        end
    end
end
