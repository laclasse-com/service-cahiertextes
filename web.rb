# coding: utf-8

# -*- encoding: utf-8 -*-

require 'rubygems'
require 'bundler'

require_relative './config/init'

Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

require_relative './lib/AuthenticationHelpers'

# Application Sinatra servant de base
module CahierDeTextesAPI
  class Web < Sinatra::Base

    configure :production, :development do
      set :protection, true
      set :protection, except: :frame_options
    end

    helpers AuthenticationHelpers

    before  do
      pass if %w[ auth ].include? request.path_info.split('/')[ APP_ROOT.split( '/' ).length() - 1 ]
      login! request.path_info unless is_logged?
    end

    get "#{APP_PATH}/?" do
      erb :index
    end

    # routes pour la gestion de l'authentification
    get "#{APP_PATH}/auth/:provider/callback" do
      init_session( request.env )

      redirect_uri = URI( params[:url] )
      redirect "#{redirect_uri.path}?#{redirect_uri.query}##{redirect_uri.fragment}"
    end

    get "#{APP_PATH}/logout" do
      logout! "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}#{APP_PATH}/"
    end

    # Personne ne devrait jamais arriver sur les 3 routes suivantes...
    get "#{APP_PATH}/auth/failure" do
      erb :auth_failure
    end

    get "#{APP_PATH}/auth/:provider/deauthorized" do
      erb :auth_deauthorized
    end

    get "#{APP_PATH}/login" do
      login! "#{APP_PATH}/"
    end

  end
end
