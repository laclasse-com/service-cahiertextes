#!/usr/bin/env rackup
# -*- coding: utf-8; mode: ruby -*-

require 'laclasse/helpers/rack'
require 'laclasse/laclasse_logger'
require 'laclasse/utils/health_check'

require_relative './lib/utils/deep_dup'

require ::File.expand_path( '../config/init', __FILE__ )

require ::File.expand_path( '../api', __FILE__ )
require ::File.expand_path( '../web', __FILE__ )

LOGGER = Laclasse::LoggerFactory.get_logger
LOGGER.info( "Démarrage du Cahier de Textes avec #{LOGGER.loggers_count} logger#{LOGGER.loggers_count > 1 ? 's' : ''}" )

Laclasse::Utils::HealthChecker.check

LOGGER.info 'Cahier de Textes prêt à servir'

Laclasse::Helpers::Rack.configure_rake self

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
  run CahierDeTextesAPI::API
end

run CahierDeTextesAPI::Web
