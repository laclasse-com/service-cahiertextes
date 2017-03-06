# -*- encoding: utf-8 -*-

require 'rubygems'
require 'bundler'

require_relative './config/init'

Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

require 'laclasse/helpers/authentication'
require 'laclasse/helpers/user'
require 'laclasse/helpers/app_infos'

require_relative './lib/utils/holidays'

require_relative './routes/index'
require_relative './routes/auth'
require_relative './routes/status'

# Application Sinatra servant de base
module CahierDeTextesApp
  class Web < Sinatra::Base
    helpers Laclasse::Helpers::Authentication
    helpers Laclasse::Helpers::User
    helpers Laclasse::Helpers::AppInfos

    configure :production, :development do
      set :protection, true
      set :protection, except: :frame_options
      set :show_exceptions, false
    end

    before  do
      pass if %r{#{APP_PATH}/(auth|login|status)} =~ request.path
      login!( request.path_info ) unless logged?
    end

    ##### routes #################################################################
    register CahierDeTextesApp::Routes::Index
    register CahierDeTextesApp::Routes::Auth
    register CahierDeTextesApp::Routes::Status
  end
end
