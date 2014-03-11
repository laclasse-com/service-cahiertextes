# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'

Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

require_relative './lib/AuthenticationHelpers'
require_relative './lib/UserHelpers'

require_relative './models/models'
require_relative './lib/pronote'

require_relative './api/v0/api'

module CahierDeTextesAPI
   class API < Grape::API

      helpers AuthenticationHelpers
      helpers UserHelpers

      before do
         error!( '401 Unauthorized', 401 ) unless is_logged?
      end

      mount ::CahierDeTextesAPI::V0::API
   end
end
