# This file contains your application, it requires dependencies and necessary parts of 
# the application.
#
# It will be required from either `config.ru` or `start.rb`
require 'rubygems'
require 'ramaze'

# Make sure that Ramaze knows where you are
Ramaze.options.roots = [__DIR__]

# Dependencies. Enable what you need.
require 'sequel'
require 'ramaze/helper/user'
#require 'ramaze/helper/sixpack'
#require 'fra-cas'

# Initialize controllers and models
require __DIR__('config/init')
require __DIR__('model/init')
require __DIR__('ctrl/init')
