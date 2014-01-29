# coding: utf-8

# -*- encoding: utf-8 -*-

require 'rubygems'
require 'bundler'

require_relative './config/environment'
require_relative './config/CASLaclasseCom'

Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

require_relative './lib/AuthenticationHelpers'

# Application Sinatra servant de base
module CahierDeTextesAPI
  class Web < Sinatra::Base

    configure do
      set :protection, true
    end

    helpers AuthenticationHelpers

    before  do
      pass if %w[ auth ].include? request.path_info.split('/')[1]
      login! request.path_info unless is_logged?
    end

    get '/' do
      erb :index
    end

    # routes pour la gestion de l'authentification
    get '/auth/:provider/callback' do
      init_session( request.env )

      redirect params[:url]
    end

    get '/logout' do
      logout! "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}/"
    end

    # Personne ne devrait jamais arriver sur les 3 routes suivantes...
    get '/auth/failure' do
      erb :auth_failure
    end

    get '/auth/:provider/deauthorized' do
      erb :auth_deauthorized
    end

    get '/login' do
      login! '/'
    end

  end
end
