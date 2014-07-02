# -*- encoding: utf-8 -*-

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Require settings
puts "loading config/options"
require __DIR__('options')

puts "loading config/database"
require __DIR__('database')

puts "loading config/constants"
require __DIR__('constants')