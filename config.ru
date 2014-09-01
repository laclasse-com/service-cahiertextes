#!/usr/bin/env rackup
# -*- coding: utf-8; mode: ruby -*-

require ::File.expand_path( '../config/init', __FILE__ )

require ::File.expand_path( '../api', __FILE__ )
require ::File.expand_path( '../web', __FILE__ )

use Rack::Rewrite do
  rewrite %r{^/logout/?$}, "#{APP_PATH}/logout"
  rewrite %r{^#{APP_PATH}(/.*(css|js|ttf|woff|html|png|jpg|jpeg|gif)[?v=0-9.]*$)}, '$1'
end

use Rack::Session::Cookie,
    key: 'rack.session',
    path: APP_PATH,
    expire_after: 3600, # 1 heure en secondes
    secret: SESSION_KEY

use OmniAuth::Builder do
  configure do |config|
    config.path_prefix = "#{APP_PATH}/auth"
  end
  provider :cas, CASAUTH::CONFIG
end

map "#{APP_PATH}/api" do
  run CahierDeTextesAPI::API
end

run CahierDeTextesAPI::Web
