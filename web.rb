# coding: utf-8

# -*- encoding: utf-8 -*-

require 'rubygems'
require 'bundler'

require_relative './config/init'

Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

require 'laclasse/helpers/authentication'
require 'laclasse/helpers/user'

require_relative './lib/helpers/provisioning'

# Application Sinatra servant de base
module CahierDeTextesAPI
  class Web < Sinatra::Base
    helpers Laclasse::Helpers::Authentication
    helpers Laclasse::Helpers::User

    helpers CahierDeTextesApp::Helpers::Provisioning

    configure :production, :development do
      set :protection, true
      set :protection, except: :frame_options
    end

    before  do
      pass if %r{#{APP_PATH}/(auth|login)/}.match(request.path)
      login! request.path_info unless logged?
    end

    get "#{APP_PATH}/?" do
      erb :app
    end

    get "#{APP_PATH}/rien/?" do
      erb :rien
    end

    # routes pour la gestion de l'authentification
    get "#{APP_PATH}/auth/:provider/callback" do
      init_session( request.env )

      provision( user )

      redirect_uri = URI( params[:url] )
      redirect "#{redirect_uri.path}?#{redirect_uri.query}##{redirect_uri.fragment}"
    end

    get "#{APP_PATH}/logout" do
      logout! "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{APP_PATH}/"
    end

    # Personne ne devrait jamais arriver sur les 2 routes suivantes...
    get "#{APP_PATH}/auth/failure" do
      erb :auth_failure
    end

    get "#{APP_PATH}/auth/:provider/deauthorized" do
      erb :auth_deauthorized
    end

    # Login pour les applications tierces, en mode WEB
    get "#{APP_PATH}/login/?" do
      login! "#{APP_PATH}/"
    end

    get "#{APP_PATH}/quiet_login/?" do
      login! "#{APP_PATH}/rien/"
    end

    # POST pour le login en mode REST, pour les applications souhaitant utiliser les API du Cahier de Textes.
    # Dans ce cas le paramètre restmod et requis.
    # Exemple avec curl :
    # curl --data "username=$USER&password=$PWD" --cookie-jar ./cookieCT.txt --insecure --location http://[Server]/ct/login/?restmod=Y
    # Voir le  script d'exemple dans les specs.
    # @see ./spec/api/test_login_curl_proxy.sh
    post "#{APP_PATH}/login/?" do
      login! "#{APP_PATH}/"
    end
  end
end
