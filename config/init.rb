# -*- encoding: utf-8 -*-

Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Require settings
puts 'loading config/options'
require_relative './options'

puts 'loading config/database'
require_relative './database'
