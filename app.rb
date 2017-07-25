# -*- encoding: utf-8 -*-

require 'rubygems'
require 'bundler'

require_relative './config/init'

Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

require_relative './lib/utils/holidays'

require_relative './models/cahier_de_textes'
require_relative './models/cours'
require_relative './models/creneau_emploi_du_temps'
require_relative './models/devoir'
require_relative './models/etablissement'
require_relative './models/import'
require_relative './models/matchable'
require_relative './models/models'
require_relative './models/ressource'
require_relative './models/salle'
require_relative './models/user_parameters'

require_relative './lib/helpers/user'

require_relative './routes/index'
require_relative './routes/auth'
require_relative './routes/status'
require_relative './routes/api/cahiers_de_textes'
require_relative './routes/api/cours'
require_relative './routes/api/creneaux_emploi_du_temps'
require_relative './routes/api/devoirs'
require_relative './routes/api/emplois_du_temps'
require_relative './routes/api/etablissements'
require_relative './routes/api/import'
require_relative './routes/api/matchables'
require_relative './routes/api/salles'
require_relative './routes/api/types_de_devoirs'
require_relative './routes/api/users'
require_relative './routes/api/user_parameters'

# Application Sinatra servant de base
module CahierDeTextesApp
  class CdTServer < Sinatra::Base
    use Rack::Session::Cookie,
        expire_after: SESSION_TIME,
        secret: SESSION_KEY
    # path: '/portail',
    # domain: URL_ENT.gsub( /http[s]?:\/\//, '' )

    use OmniAuth::Builder do
      provider :cas, CASAUTH::CONFIG
      configure do |config|
        config.path_prefix = '/auth'
        config.full_host = CASAUTH::CONFIG[:full_host] if ENV['RACK_ENV'] == 'production'
      end
    end

    configure :production, :development do
      set :sessions, true
      set :protection, true
      set :protection, except: :frame_options
      set :show_exceptions, false
    end

    # helpers Sinatra::Param
    helpers LaClasse::Helpers::User

    ##### routes #################################################################

    before do
      pass if request.path =~ %r{#{APP_PATH}/(auth|login|status)/}

      cache_control :no_cache

      redirect "#{APP_PATH}/auth/cas/?url=#{request.env['REQUEST_PATH']}" unless env['rack.session']['authenticated']
    end

    register LaClasse::Routes::Auth

    register CahierDeTextesApp::Routes::Index
    register CahierDeTextesApp::Routes::Status

    register CahierDeTextesApp::Routes::Api::CahiersDeTextes
    register CahierDeTextesApp::Routes::Api::CoursAPI
    register CahierDeTextesApp::Routes::Api::CreneauxEmploiDuTemps
    register CahierDeTextesApp::Routes::Api::Devoirs
    register CahierDeTextesApp::Routes::Api::EmploisDuTemps
    register CahierDeTextesApp::Routes::Api::Etablissements
    register CahierDeTextesApp::Routes::Api::ImportAPI
    register CahierDeTextesApp::Routes::Api::Matchables
    register CahierDeTextesApp::Routes::Api::Salles
    register CahierDeTextesApp::Routes::Api::TypesDeDevoir

    register CahierDeTextesApp::Routes::Api::UsersAPI
    register CahierDeTextesApp::Routes::Api::UserParametersAPI
  end
end
