module CahierDeTextesApp
  module Routes
    module Api
      module Matchables
        def self.registered( app )
          app.get '/api/matchables/:uai/?' do
            etab = Structure[ UAI: params[:uai] ]
            halt( 404, "Structure #{params[:uai]} unknown" ) if etab.nil?

            json( Matchable.where( structure_id: etab.id ).all )
          end

          app.get '/api/matchables/:uai/:hash_item/?' do
            etab = Structure[ UAI: params[:uai] ]
            halt( 404, "Structure #{params[:uai]} unknown" ) if etab.nil?

            fi = Matchable[ structure_id: etab.id,
                            hash_item: params[:hash_item] ]
            halt( 404, "No match for #{params[:hash_item]}" ) if fi.nil?

            json( fi.to_hash )
          end

          app.post '/api/matchables/:uai/:hash_item/?' do
            etab = Structure[ UAI: params[:uai] ]
            halt( 404, "Structure #{params[:uai]} unknown" ) if etab.nil?

            fi = Matchable[ structure_id: etab.id, hash_item: params[:hash_item] ]
            fi = Matchable.create( structure_id: etab.id, hash_item: params[:hash_item] ) if fi.nil?

            fi.update( id_annuaire: params[:id_annuaire] )
            fi.save

            json( fi.to_hash )
          end

          app.delete '/api/matchables/:uai/:hash_item/?' do
            etab = Structure[ UAI: params[:uai] ]
            halt( 404, "Structure #{params[:uai]} unknown" ) if etab.nil?

            fi = Matchable[ structure_id: etab.id,
                            hash_item: params[:hash_item] ]
            fi.destroy unless fi.nil?

            nil
          end
        end
      end
    end
  end
end
