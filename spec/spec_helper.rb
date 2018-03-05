# -*- coding: utf-8 -*-
require 'rubygems'

ENV['RACK_ENV'] ||= 'test'

require 'sequel'
require 'tsort'
require 'rspec/matchers' # required by equivalent-xml custom matcher `be_equivalent_to`
require 'equivalent-xml'

require_relative '../config/options'

require_relative '../app'

require_relative './helper_lib/table_cleaner'
require_relative './helper_lib/test_data'
require_relative './helper_mocks/helpers/authentication'
require_relative './helper_mocks/mocked_data'

RSpec.configure do |config|
  config.mock_with :rspec
  config.expect_with :rspec
  config.color = true # Use color in STDOUT
  config.tty = true # Use color not only in STDOUT but also in pagers and files
  config.formatter = :documentation # Use the specified formatter: :progress, :html, :textmate, :documentation
end
