# frozen_string_literal: true

ENV['RACK_ENV'] = 'development'

require 'rack/test'

require_relative '../app'
require_relative './mocks'
