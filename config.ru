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

require ::File.expand_path( '../auth-app', __FILE__ )
require ::File.expand_path( '../api', __FILE__ )

APP_VIRTUAL_PATH = '/'

use Rack::Session::Cookie,
    key: 'rack.session',
    path: '/',
    expire_after: 3600, # In seconds
    secret: 'e862960f7140cc24c8e933fd0bfa5f3bd8cdc6c3' # Digest::SHA1.hexdigest( SecureRandom.base64 )

use OmniAuth::Builder do
  provider :cas, CASLaclasseCom::OPTIONS
end

if %W[ 'development', 'test' ].include? ENV['RACK_ENV']
  api.logger.info 'Enabling Developer authentication.'
  use OmniAuth::Strategies::Developer
end

run Rack::Cascade.new [ CahierDeTextesAPI::API, CahierDeTextesAPI::AuthApp ]
