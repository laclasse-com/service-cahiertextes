require 'rubygems'

ENV["RACK_ENV"] ||= 'test'

require 'rack/test'
require 'sequel'

require_relative '../config/environment'
require_relative '../config/database'

RSpec.configure do |config|
  config.mock_with :rspec
  config.expect_with :rspec
end

require_relative '../app'
