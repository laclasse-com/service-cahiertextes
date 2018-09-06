# coding: utf-8
require 'rubygems'
require 'bundler'
require 'yaml'

Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

require_relative './config/init'

DB_CONFIG = YAML.safe_load( File.read( './config/database.yml' ) )
DB = Sequel.mysql2( DB_CONFIG[:name],
                    DB_CONFIG )

Sequel.extension( :migration )
Sequel::Model.plugin( :json_serializer )

require_relative './lib/utils/holidays'

require_relative './models/textbook'
require_relative './models/session'
require_relative './models/timeslot'
require_relative './models/devoir'
require_relative './models/structure'
require_relative './models/import'
require_relative './models/matchable'
require_relative './models/models'
require_relative './models/resource'
require_relative './models/location'
require_relative './models/user_parameters'

require_relative './lib/helpers/auth'
require_relative './lib/helpers/user'

require_relative './routes/status'
require_relative './routes/api/textbooks'
require_relative './routes/api/sessions'
require_relative './routes/api/timeslots'
require_relative './routes/api/devoirs'
require_relative './routes/api/emplois_du_temps'
require_relative './routes/api/structures'
require_relative './routes/api/import'
require_relative './routes/api/matchables'
require_relative './routes/api/locations'
require_relative './routes/api/types_de_devoirs'
require_relative './routes/api/users'
require_relative './routes/api/user_parameters'

# Application Sinatra servant de base
module CahierDeTextesApp
  class CdTServer < Sinatra::Base
    helpers Sinatra::Helpers
    helpers Sinatra::Cookies

    helpers LaClasse::Helpers::Auth
    helpers LaClasse::Helpers::User

    configure :production, :development do
      set :protection, true
      set :protection, except: :frame_options
      set :show_exceptions, false
    end

    not_found do
      "Page non trouvée\n"
    end

    error do
      status 500

      log_exception env['sinatra.error']
      'Erreur Interne au serveur'
    end

    ##### routes #################################################################

    before do
      cache_control :no_cache

      pass if request.path =~ %r{#{APP_PATH}/status/}

      login! env['REQUEST_PATH'] unless logged?
    end

    register CahierDeTextesApp::Routes::Status

    register CahierDeTextesApp::Routes::Api::TextBooks
    register CahierDeTextesApp::Routes::Api::Sessions
    register CahierDeTextesApp::Routes::Api::Timeslots
    register CahierDeTextesApp::Routes::Api::Devoirs
    register CahierDeTextesApp::Routes::Api::EmploisDuTemps
    register CahierDeTextesApp::Routes::Api::Structures
    register CahierDeTextesApp::Routes::Api::Locations
    register CahierDeTextesApp::Routes::Api::TypesDeDevoir

    register CahierDeTextesApp::Routes::Api::ImportAPI
    register CahierDeTextesApp::Routes::Api::Matchables

    register CahierDeTextesApp::Routes::Api::UsersAPI
    register CahierDeTextesApp::Routes::Api::UserParametersAPI
  end
end
