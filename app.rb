# This file contains your application, it requires dependencies and necessary parts of 
# the application.
#
# It will be required from either `config.ru` or `start.rb`
#
# Launch commande : bundle exec thin start -p 7000
#
require 'rubygems'
require 'ramaze'

# Make sure that Ramaze knows where you are
Ramaze.options.roots = [__DIR__]

# Dependencies. Enable what you need.
require 'yaml'
require 'sequel'
require 'ramaze/helper/user'
require 'json'
#require 'fra-cas'
#require 'sixpack'

# Reading YAML Config.
def readconf
  conf = Hash.new
  Dir.glob('./config/*.yml').each { |f| 
    puts "Loading " + f + "..." 
    conf.merge! YAML::load(File.open(f))    
  } 
  conf
end

CFG = readconf

# Initialize controllers and models
require __DIR__('config/init') 
require __DIR__('model/init')
require __DIR__('controller/init')

