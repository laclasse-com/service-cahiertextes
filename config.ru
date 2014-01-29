#!/usr/bin/env rackup
# -*- coding: utf-8; mode: ruby -*-
#
# Rackup is a useful tool for running Rack applications, which uses the
# Rack::Builder DSL to configure middleware and build up applications easily.
#
# Rackup automatically figures out the environment it is run in, and runs your
# application as FastCGI, CGI, or standalone with Mongrel or WEBrick -- all from
# the same configuration.

require ::File.expand_path( '../config/CASLaclasseCom', __FILE__ )
require ::File.expand_path( '../config/environment', __FILE__ )
require ::File.expand_path( '../config/options', __FILE__ )

require ::File.expand_path( '../api', __FILE__ )
require ::File.expand_path( '../web', __FILE__ )

use Rack::Rewrite do
  rewrite %r{/api/(.*)}, '/ct/api/$1'
  rewrite %r{/ct/(.*(css|js|ttf|woff|html|png|jpg|jpeg|gif))}, '/$1'
end

use Rack::Session::Cookie,
    key: 'rack.session',
    path: APP_VIRTUAL_PATH,
    expire_after: 3600, # In seconds
    secret: 'e862960f7140cc24c8e933fd0bfa5f3bd8cdc6c3' # Digest::SHA1.hexdigest( SecureRandom.base64 )

use OmniAuth::Builder do
  configure do |config|
    config.path_prefix =  "#{APP_VIRTUAL_PATH}/auth"
  end
  provider :cas, CASLaclasseCom::OPTIONS
end

map "#{APP_VIRTUAL_PATH}/api" do
  run CahierDeTextesAPI::API
end

run CahierDeTextesAPI::Web
