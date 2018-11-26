# frozen_string_literal: true

require_relative '../../lib/utils'

module Routes
    module Api
        module Holidays
            def self.registered( app )
                app.get '/api/holidays/?' do
                    json( Utils::Calendar.holidays( 'A' ) ) # FIXME: hardcoded zone
                end
            end
        end
    end
end
