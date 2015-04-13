# -*- encoding: utf-8 -*-

Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# DIR Method
def __DIR__(*args)
  filename = caller[0][/^(.*):/, 1]
  dir = File.expand_path(File.dirname(filename))
  ::File.expand_path( ::File.join( dir, *args.map(&:to_s) ) )
end

# Require settings
puts 'loading config/options'
require __DIR__('options')

puts 'loading config/database'
require __DIR__('database')

puts 'loading config/constants'
require __DIR__('constants')

puts 'loading config/internal_constants'
require __DIR__('internal_constants')
