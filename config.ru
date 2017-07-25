# -*- coding: utf-8; mode: ruby -*-

require_relative './app'

STDERR.puts "#{ENV['RACK_ENV']} environment"

map "#{APP_PATH}/" do
  run CahierDeTextesApp::CdTServer
end
