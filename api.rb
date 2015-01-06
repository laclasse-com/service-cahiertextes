# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'

Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

require_relative './helpers/Authentication'
require_relative './helpers/User'
require_relative './helpers/DataExtraction'

require_relative './models/models'
require_relative './lib/data_management'
require_relative './lib/pronote'

require_relative './api/v1/api'

module CahierDeTextesAPI
  class API < Grape::API

    helpers AuthenticationHelpers
    helpers UserHelpers
    helpers DataExtractionHelpers

    format :txt
    get '/version' do
      APP_VERSION
    end

    before do
      error!( '401 Unauthorized', 401 ) unless is_logged? || !request.env['PATH_INFO'].match(/.*swagger.*\.json$/).nil?
    end

    mount ::CahierDeTextesAPI::V1::API
  end
end
