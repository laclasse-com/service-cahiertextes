# coding: utf-8

ENV['RACK_ENV'] = 'development'

task :load_config do
  require 'rubygems'
  require 'bundler'
  require 'open-uri'
  require 'uri'
  require 'json'
  require 'yaml'
  require 'sequel'
  require 'pry'

  Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

  require_relative '../config/constants'
  require_relative '../lib/pronote'
  require_relative '../config/database'
  require_relative '../models/models'
  require_relative '../lib/utils/semainier'
end

desc 'Open pry with app environment'
task pry: :load_config do
  LOGGER = Laclasse::LoggerFactory.get_logger
  pry.binding
end
