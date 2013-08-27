#!/usr/bin/env rackup
#
# config.ru for ramaze apps
#
# Rackup is a useful tool for running Rack applications, which uses the
# Rack::Builder DSL to configure middleware and build up applications easily.
#
# Rackup automatically figures out the environment it is run in, and runs your
# application as FastCGI, CGI, or standalone with Mongrel or WEBrick -- all from
# the same configuration.
require ::File.expand_path('../app', __FILE__)

run CahierDeTextesAPI::API
