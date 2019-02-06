# frozen_string_literal: true

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

# Uncomment this if you want to log all DB queries
# DB.loggers << Logger.new($stdout)

require_relative './lib/utils'

require_relative './models/timeslot'
require_relative './models/session'
require_relative './models/assignment'
require_relative './models/note'
require_relative './models/import'
require_relative './models/matchable'
require_relative './models/attachment'
require_relative './models/resource'
require_relative './models/users'
require_relative './models/trail'

require_relative './lib/helpers/auth'
require_relative './lib/helpers/user'

require_relative './routes/api/notes'
require_relative './routes/api/sessions'
require_relative './routes/api/timeslots'
require_relative './routes/api/assignments'
require_relative './routes/api/import'
require_relative './routes/api/matchables'
require_relative './routes/api/resources'
require_relative './routes/api/assignment_types'
require_relative './routes/api/resource_types'
require_relative './routes/api/import_types'
require_relative './routes/api/attachment_types'
require_relative './routes/api/trails'
require_relative './routes/api/users'
require_relative './routes/api/holidays'

# Application Sinatra servant de base
class CdTServer < Sinatra::Base
    helpers Sinatra::Helpers
    helpers Sinatra::Cookies
    helpers Sinatra::Param

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

        request.path.match( %r{#{APP_PATH}/(status|__sinatra__)[/]?.*} ) do
            pass
        end

        login!( request.path ) unless logged?
    end

    register Routes::Api::Timeslots
    register Routes::Api::Sessions
    register Routes::Api::Assignments
    register Routes::Api::AssignmentTypes
    register Routes::Api::Notes
    register Routes::Api::Resources
    register Routes::Api::ResourceTypes
    register Routes::Api::ImportTypes
    register Routes::Api::AttachmentTypes
    register Routes::Api::Trails

    register Routes::Api::ImportAPI
    register Routes::Api::Matchables

    register Routes::Api::UsersAPI

    register Routes::Api::Holidays
end
