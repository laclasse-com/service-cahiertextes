# frozen_string_literal: true

module Routes
    module Api
        module Trails
            def self.registered( app )
                app.get '/api/trails/?' do
                    Trail.all.map(&:to_hash).to_json
                end

                app.get '/api/trails/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    trail = Trail[ params['id'] ]
                    halt( 404, "Trail #{params['id']} inconnu" ) if trail.nil?

                    json( trail.to_hash )
                end

                app.post '/api/trails/?' do
                    # {
                    param 'label', String, required: true
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    trail = Trail[ label: params['label'] ]
                    halt( 403, "Trail #{params['label']} existant" ) unless trail.nil?

                    trail = Trail.create( label: params['label'] )

                    json( trail.to_hash )
                end

                app.put '/api/trails/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    param 'label', String, required: true
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    trail = Trail[ params['id'] ]
                    halt( 404, "Trail #{params['id']} inconnu" ) if trail.nil?

                    overlapping_trail = Trail[ label: params['label'] ]
                    halt( 403, "Trail #{params['label']} existant" ) unless overlapping_trail.nil?

                    trail.update( label: params['label'] )

                    json( trail.to_hash )
                end

                app.delete '/api/trails/:id/?' do
                    # {
                    param 'id', Integer, required: true
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_super_admin?

                    trail = Trail[ params['id'] ]
                    halt( 404, "Trail #{params['id']} inconnu" ) if trail.nil?

                    trail&.destroy

                    nil
                end
            end
        end
    end
end
