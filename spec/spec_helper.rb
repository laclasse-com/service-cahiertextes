# -*- coding: utf-8 -*-
require 'rubygems'

ENV['RACK_ENV'] ||= 'test'

require 'rack/test'
require 'sequel'
require 'tsort'
require 'rspec/matchers' # required by equivalent-xml custom matcher `be_equivalent_to`
require 'equivalent-xml'

require_relative '../config/constants'
require_relative '../config/options'
require_relative '../config/database'

require_relative '../api'
require_relative '../web'

require_relative './helper_lib/table_cleaner'
require_relative './helper_lib/test_data'
require_relative './helper_mocks/helpers/authentication'
require_relative './helper_mocks/lib/annuaire_wrapper'
require_relative './helper_mocks/mocked_data'

require 'laclasse/laclasse_logger'

LOGGER = Laclasse::LoggerFactory.get_logger
LOGGER.info("Démarrage des test du Cahier de Textes avec #{LOGGER.loggers_count} logger#{LOGGER.loggers_count > 1 ? 's' : ''}")

RSpec.configure do |config|
  config.mock_with :rspec
  config.expect_with :rspec
  config.color = true # Use color in STDOUT
  config.tty = true # Use color not only in STDOUT but also in pagers and files
  config.formatter = :documentation # Use the specified formatter: :progress, :html, :textmate, :documentation

  config.include ShowMeTheCookies, type: :feature
end
