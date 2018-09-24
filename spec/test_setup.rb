# frozen_string_literal: true

ENV['RACK_ENV'] = 'development'

require 'rack/test'

require_relative '../app'
require_relative './mocks'

RSpec.configure do |config|
    config.mock_with :rspec
    config.expect_with :rspec
    config.color = true # Use color in STDOUT
    config.tty = true # Use color not only in STDOUT but also in pagers and files
    config.formatter = :documentation # Use the specified formatter: :progress, :html, :textmate, :documentation
end
