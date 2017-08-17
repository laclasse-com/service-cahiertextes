# -*- coding: utf-8 -*-

module CahierDeTextesApp
  module Routes
    module Api
      module TypesDeDevoir
        def self.registered( app )
          app.get '/api/types_de_devoir/?' do
            TypeDevoir.all.map(&:to_hash).to_json
          end

          app.get '/api/types_de_devoir/:id/?' do
            type_de_devoir = TypeDevoir[ params[:id] ]
            halt( 404, "TypeDevoir #{params[:id]} inconnue" ) if type_de_devoir.nil?

            json( type_de_devoir.to_hash )
          end
        end
      end
    end
  end
end
