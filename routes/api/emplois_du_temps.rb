require_relative '../../lib/data_management'

module CahierDeTextesApp
  module Routes
    module Api
      module EmploisDuTemps
        def self.registered( app )
          app.get '/api/emplois_du_temps/?' do
            json( DataManagement::EmploiDuTemps.get( Date.parse( params['debut'] ).iso8601,
                                                     Date.parse( params['fin'] ).iso8601,
                                                     params.key?('groups_ids') ? params['groups_ids'] : user_regroupements_ids( params['uid'] ),
                                                     params.key?('subjects_ids') && !params['subjects_ids'].empty? ? params['subjects_ids'] : nil,
                                                     user_active_profile['type'] == 'ELV' ? user['id'] : params['uid'] ) )
          end
        end
      end
    end
  end
end
