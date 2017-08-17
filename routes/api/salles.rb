# -*- coding: utf-8 -*-

module CahierDeTextesApp
  module Routes
    module Api
      module Salles
        def self.registered( app )
          app.get '/api/salles/?' do
            json( Salles.all )
          end

          app.get '/api/salles/:id/?' do
            # param :id, Integer, required: true

            salle = Salle[ params[:id] ]
            halt( 404, "Salle #{params[:id]} inconnue" ) if salle.nil?

            json( salle )
          end

          app.post '/api/salles/?' do
            # param :uai, String, required: true
            # param :identifiant, String, required: true
            # param :nom, String, required: true

            etablissement = Etablissement.where(uai: params[:uai]).first
            halt( 404, "Établissement #{params[:uai]} inconnu" ) if etablissement.nil?

            salle = DataManagement::Accessors.create_or_get( Salle,
                                                             identifiant: params[:identifiant] )
            salle.update( nom: params[:nom],
                          etablissement_id: etablissement.id )
            salle.save

            json( salle )
          end

          app.post '/api/salles/bulk/?' do
            user_needs_to_be( %w[ ADM DIR ] )

            request.body.rewind
            body = JSON.parse( request.body.read )

            json( body['salles'].map do |salle|
                    etablissement = Etablissement.where(uai: salle['uai']).first
                    halt( 404, "Établissement #{params[:uai]} inconnu" ) if etablissement.nil?

                    new_salle = DataManagement::Accessors.create_or_get( Salle,
                                                                         identifiant: salle['identifiant'] )
                    new_salle.update( nom: salle['nom'],
                                      etablissement_id: etablissement.id )
                    new_salle.save

                    new_salle.to_hash
                  end )
          end

          app.put '/api/salles/:id/?' do
            # param :id, Integer, required: true
            # param :uai, String, required: false
            # param :identifiant, String, required: false
            # param :nom, String, required: false

            salle = Salle[ params[:id] ]

            halt( 404, "Salle #{params[:id]} inconnue" ) if salle.nil?

            if params.key? :uai
              etablissement = Etablissement.where(uai: params[:uai]).first

              halt( 404, "Établissement #{params[:uai]} inconnu" ) if etablissement.nil?

              salle.etablissement_id = params[:uai]
            end
            salle.identifiant = params[:identifiant] if params.key? :identifiant
            salle.nom = params[:nom] if params.key? :nom
            salle.save

            json( salle )
          end

          app.delete '/api/salles/:id/?' do
            # param :id, Integer, required: true

            salle = Salle[ params[:id] ]

            halt( 404, "Salle #{params[:id]} inconnue" ) if salle.nil?

            json( salle.destroy )
          end
        end
      end
    end
  end
end
