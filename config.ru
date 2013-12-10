#!/usr/bin/env rackup
# -*- coding: utf-8; mode: ruby -*-
#
# Rackup is a useful tool for running Rack applications, which uses the
# Rack::Builder DSL to configure middleware and build up applications easily.
#
# Rackup automatically figures out the environment it is run in, and runs your
# application as FastCGI, CGI, or standalone with Mongrel or WEBrick -- all from
# the same configuration.

require 'securerandom'
require 'digest'

require ::File.expand_path( '../config/CASLaclasseCom', __FILE__ )
require ::File.expand_path( '../config/environment', __FILE__ )

require ::File.expand_path( '../auth-app', __FILE__ )
require ::File.expand_path( '../api', __FILE__ )

APP_VIRTUAL_PATH = '/'

use Rack::Static,
    root: File.expand_path('../public', __FILE__),
    urls: %w[/app],
    try: [ '.html',
           'index.html',
           '/index.html',
           '/bower_components',
           '/favicon.ico',
           '/localcdn',
           '/mocks',
           '/robots.txt',
           '/scripts',
           '/styles',
           '/views' ]

use Rack::Session::Cookie,
    key: 'rack.session',
    path: '/',
    expire_after: 3600, # In seconds
    secret: Digest::SHA1.hexdigest( SecureRandom.base64 ) # test only

use OmniAuth::Builder do
  provider :cas, CASLaclasseCom::OPTIONS
end

if %W[ 'development', 'test' ].include? ENV['RACK_ENV']
  api.logger.info 'Enabling Developer authentication.'
  use OmniAuth::Strategies::Developer
end

run Rack::Cascade.new [ CahierDeTextesAPI::API, CahierDeTextesAPI::AuthApp ]
