# coding: utf-8
module CahierDeTextesApp
    module Routes
        module Api
            module Locations
                def self.registered( app )
                    app.get '/api/locations/?' do
                        json( Locations.all )
                    end

                    app.get '/api/locations/:id/?' do
                        location = Location[ params[:id] ]
                        halt( 404, "Location #{params[:id]} inconnue" ) if location.nil?

                        json( location )
                    end

                    app.post '/api/locations/?' do
                        structure = Structure.where(uai: params[:uai]).first
                        halt( 404, "Établissement #{params[:uai]} inconnu" ) if structure.nil?

                        location = DataManagement::Accessors.create_or_get( Location,
                                                                            label: params[:label] )
                        location.update( nom: params[:nom],
                                         structure_id: structure.id )
                        location.save

                        json( location )
                    end

                    app.post '/api/locations/bulk/?' do
                        user_needs_to_be( %w[ ADM DIR ] )

                        request.body.rewind
                        body = JSON.parse( request.body.read )

                        json( body['locations'].map do |location|
                                  structure = Structure.where(uai: location['uai']).first
                                  halt( 404, "Établissement #{params[:uai]} inconnu" ) if structure.nil?

                                  new_location = DataManagement::Accessors.create_or_get( Location,
                                                                                          label: location['label'] )
                                  new_location.update( nom: location['nom'],
                                                       structure_id: structure.id )
                                  new_location.save

                                  new_location.to_hash
                              end )
                    end

                    app.put '/api/locations/:id/?' do
                        location = Location[ params[:id] ]

                        halt( 404, "Location #{params[:id]} inconnue" ) if location.nil?

                        if params.key? :uai
                            structure = Structure.where(uai: params[:uai]).first

                            halt( 404, "Établissement #{params[:uai]} inconnu" ) if structure.nil?

                            location.structure_id = params[:uai]
                        end
                        location.label = params[:label] if params.key? :label
                        location.nom = params[:nom] if params.key? :nom
                        location.save

                        json( location )
                    end

                    app.delete '/api/locations/:id/?' do
                        location = Location[ params[:id] ]

                        halt( 404, "Location #{params[:id]} inconnue" ) if location.nil?

                        json( location.destroy )
                    end
                end
            end
        end
    end
end
