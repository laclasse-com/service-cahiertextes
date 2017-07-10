#!/usr/bin/env rackup
# -*- coding: utf-8; mode: ruby -*-

require_relative './lib/utils/deep_dup'

require ::File.expand_path( '../config/init', __FILE__ )

require ::File.expand_path( '../api', __FILE__ )
require ::File.expand_path( '../web', __FILE__ )

use Rack::Session::Cookie,
    expire_after: SESSION_TIME,
    secret: SESSION_KEY
# path: '/portail',
# domain: URL_ENT.gsub( /http[s]?:\/\//, '' )

use Rack::Rewrite do
  rewrite %r{^/logout/?$}, "#{APP_PATH}/logout"
  rewrite %r{^#{APP_PATH}(/app/(js|css|node_modules)/.*(map|css|js|ttf|woff|html|png|jpg|jpeg|gif|svg)[?v=0-9a-zA-Z\-.]*$)}, '$1'
end

use OmniAuth::Builder do
  configure do |config|
    config.path_prefix = "#{APP_PATH}/auth"
  end
  provider :cas, CASAUTH::CONFIG
end

STDERR.puts "#{ENV['RACK_ENV']} environment"

map "#{APP_PATH}/api" do
  run CahierDeTextesApp::API
end

run CahierDeTextesApp::Web
