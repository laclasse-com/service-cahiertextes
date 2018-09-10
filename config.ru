# frozen_string_literal: true

require_relative './app'

STDERR.puts "#{ENV['RACK_ENV']} environment"

# vv merge POST/... body into params
use Rack::NestedParams
use Rack::PostBodyContentTypeParser

map "#{APP_PATH}/" do
    run CdTServer
end
