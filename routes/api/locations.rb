# frozen_string_literal: true

module Routes
    module Api
        module Locations
            def self.registered( app )
                app.get '/api/locations/?' do
                    # {
                    param 'structure_id', String
                    param 'label', String
                    param 'name', String
                    # }

                    user_needs_to_be( %w[ ADM DIR ] )

                    query = Location

                    query = query.where( structure_id: params['structure_id'] ) if params.key?( 'structure_id' )
                    query = query.where( label: params['label'] ) if params.key?( 'label' )
                    query = query.where( name: params['name'] ) if params.key?( 'name' )

                    json( query.all )
                end

                app.get '/api/locations/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    location = Location[ params['id'] ]
                    halt( 404, "Location #{params['id']} inconnue" ) if location.nil?

                    json( location )
                end

                app.post '/api/locations/?' do
                    # {
                    param 'structure_id', String
                    param 'label', String
                    param 'name', String

                    param 'locations', Array

                    one_of 'label', 'locations'
                    # }

                    user_needs_to_be( %w[ ADM DIR ] )

                    single = !params.key?( 'locations' )
                    if single
                        params['locations'] = [ { structure_id: params['structure_id'],
                                                  label: params['label'],
                                                  name: params['name'] } ]
                    end

                    result = json( params['locations'].map do |location|
                                       new_location = DataManagement::Accessors.create_or_get( Location,
                                                                                               structure_id: location['structure_id'],
                                                                                               label: location['label'] )

                                       new_location.name = location['name']
                                       new_location.save

                                       new_location.to_hash
                                   end )

                    result = result.first if single

                    json( result.to_hash )
                end

                app.put '/api/locations/:id/?' do
                    # {
                    param 'id', Integer, require: true
                    param 'structure_id', String, required: true
                    param 'name', String, required: true
                    param 'label', String, required: true
                    # }

                    location = Location[ params['id'] ]

                    halt( 404, "Location #{params['id']} inconnue" ) if location.nil?

                    location.structure_id = params['structure_id']

                    location.label = params['label']
                    location.name = params['name']
                    location.save

                    json( location )
                end

                app.delete '/api/locations/:id/?' do
                    # {
                    param 'id', Integer, require: true
                    # }

                    location = Location[ params['id'] ]

                    halt( 404, "Location #{params['id']} inconnue" ) if location.nil?

                    json( location.destroy )
                end
            end
        end
    end
end
