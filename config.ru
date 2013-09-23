#!/usr/bin/env rackup
# -*- coding: utf-8; mode: ruby -*-
#
# Rackup is a useful tool for running Rack applications, which uses the
# Rack::Builder DSL to configure middleware and build up applications easily.
#
# Rackup automatically figures out the environment it is run in, and runs your
# application as FastCGI, CGI, or standalone with Mongrel or WEBrick -- all from
# the same configuration.

require ::File.expand_path('../app', __FILE__)

use( Rack::Static,
     root: File.expand_path('../public', __FILE__),
     urls: %w[/app],
     try: [ '.html', 'index.html', '/index.html', '/bower_components', '/favicon.ico', '/localcdn', '/mocks', '/robots.txt', '/scripts', '/styles', '/views' ]
     )

run CahierDeTextesAPI::API
