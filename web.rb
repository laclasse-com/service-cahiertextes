# -*- encoding: utf-8 -*-

require 'rubygems'
require 'bundler'

require_relative './config/init'

Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

require_relative './lib/helpers/user'

require_relative './lib/utils/holidays'

require_relative './routes/index'
require_relative './routes/auth'
require_relative './routes/status'

# Application Sinatra servant de base
module CahierDeTextesApp
  class Web < Sinatra::Base
    helpers LaClasse::Helpers::User

    configure :production, :development do
      set :protection, true
      set :protection, except: :frame_options
      set :show_exceptions, false
    end

    before do
      cache_control :no_cache

      pass if request.path =~ %r{#{APP_PATH}/(auth|login|status)/}

      redirect "#{APP_PATH}/auth/cas/?url=#{request.env['REQUEST_PATH']}" unless env['rack.session']['authenticated']
    end

    ##### routes #################################################################
    register CahierDeTextesApp::Routes::Index
    register CahierDeTextesApp::Routes::Auth
    register CahierDeTextesApp::Routes::Status
  end
end
