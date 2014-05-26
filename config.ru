#!/usr/bin/env rackup
# -*- coding: utf-8; mode: ruby -*-

require ::File.expand_path( '../config/CAS', __FILE__ )
require ::File.expand_path( '../config/options', __FILE__ )

require ::File.expand_path( '../api', __FILE__ )
require ::File.expand_path( '../web', __FILE__ )

use Rack::Rewrite do
  rewrite %r{^/logout/?$}, "#{APP_VIRTUAL_PATH}/logout"
  rewrite %r{^#{APP_VIRTUAL_PATH}(/.*(css|js|ttf|woff|html|png|jpg|jpeg|gif)$)}, '$1'
end

use Rack::Session::Cookie,
    key: 'rack.session',
    path: APP_VIRTUAL_PATH,
    expire_after: 3600, # 1 heure en secondes
    secret: 'e862960f7140cc24c8e933fd0bfa5f3bd8cdc6c3' # Digest::SHA1.hexdigest( SecureRandom.base64 )

use OmniAuth::Builder do
  configure do |config|
    config.path_prefix = "#{APP_VIRTUAL_PATH}/auth"
  end
  provider :cas, CASAuth::OPTIONS
end

map "#{APP_VIRTUAL_PATH}/api" do
  run CahierDeTextesAPI::API
end

run CahierDeTextesAPI::Web
