# coding: utf-8

module Routes
    module Api
        module Locations
            def self.registered( app )
                app.get '/api/locations/?' do
                    json( Locations.all )
                end

                app.get '/api/locations/:id/?' do
                    # {
                    param :id, Integer, required: true
                    # }

                    location = Location[ params['id'] ]
                    halt( 404, "Location #{params[:id]} inconnue" ) if location.nil?

                    json( location )
                end

                app.post '/api/locations/?' do
                    # {
                    param :uai, String, required: true
                    param :name, String, required: true
                    param :label, String, required: true
                    # }

                    structure = Structure.where(uai: params['uai']).first
                    halt( 404, "Établissement #{params[:uai]} inconnu" ) if structure.nil?

                    location = DataManagement::Accessors.create_or_get( Location,
                                                                        label: params['label'] )
                    location.update( name: params['name'],
                                     structure_id: structure.id )
                    location.save

                    json( location )
                end

                app.post '/api/locations/bulk/?' do
                    # {
                    param :locations, Array, required: true
                    # }

                    user_needs_to_be( %w[ ADM DIR ] )

                    json( params['locations'].map do |location|
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
                    # {
                    param :id, Integer, require: true
                    param :uai, String, required: true
                    param :name, String, required: true
                    param :label, String, required: true
                    # }

                    location = Location[ params['id'] ]

                    halt( 404, "Location #{params[:id]} inconnue" ) if location.nil?

                    structure = Structure.where(uai: params['uai']).first

                    halt( 404, "Établissement #{params['uai']} inconnu" ) if structure.nil?

                    location.structure_id = structure.id

                    location.label = params['label']
                    location.nom = params['name']
                    location.save

                    json( location )
                end

                app.delete '/api/locations/:id/?' do
                    # {
                    param :id, Integer, require: true
                    # }

                    location = Location[ params['id'] ]

                    halt( 404, "Location #{params['id']} inconnue" ) if location.nil?

                    json( location.destroy )
                end
            end
        end
    end
end
