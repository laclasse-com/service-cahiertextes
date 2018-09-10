module Routes
    module Api
        module Matchables
            def self.registered( app )
                app.get '/api/matchables/:uai/?' do
                    # {
                    param :uai, String, required: true
                    # }

                    etab = Structure[ UAI: params['uai'] ]
                    halt( 404, "Structure #{params[:uai]} unknown" ) if etab.nil?

                    json( Matchable.where( structure_id: etab.id ).all )
                end

                app.get '/api/matchables/:uai/:hash_item/?' do
                    # {
                    param :uai, String, required: true
                    param :hash_item, String, required: true
                    # }

                    etab = Structure[ UAI: params['uai'] ]
                    halt( 404, "Structure #{params['uai']} unknown" ) if etab.nil?

                    fi = Matchable[ structure_id: etab.id,
                                    hash_item: params['hash_item'] ]
                    halt( 404, "No match for #{params['hash_item']}" ) if fi.nil?

                    json( fi.to_hash )
                end

                app.post '/api/matchables/:uai/:hash_item/?' do
                    # {
                    param :uai, String, required: true
                    param :hash_item, String, required: true
                    param :known_id, String, required: true
                    # }

                    etab = Structure[ UAI: params['uai'] ]
                    halt( 404, "Structure #{params['uai']} unknown" ) if etab.nil?

                    fi = Matchable[ structure_id: etab.id, hash_item: params['hash_item'] ]
                    fi = Matchable.create( structure_id: etab.id, hash_item: params['hash_item'] ) if fi.nil?

                    fi.update( known_id: params['known_id'] )
                    fi.save

                    json( fi.to_hash )
                end

                app.delete '/api/matchables/:uai/:hash_item/?' do
                    # {
                    param :uai, String, required: true
                    param :hash_item, String, required: true
                    # }

                    etab = Structure[ UAI: params['uai'] ]
                    halt( 404, "Structure #{params['uai']} unknown" ) if etab.nil?

                    fi = Matchable[ structure_id: etab.id,
                                    hash_item: params['hash_item'] ]
                    fi.destroy unless fi.nil?

                    nil
                end
            end
        end
    end
end
