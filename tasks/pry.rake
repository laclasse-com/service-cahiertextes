# coding: utf-8

ENV['RACK_ENV'] = 'development'
namespace :pry do
  task :load_config do
    require 'rubygems'
    require 'bundler'
    require 'open-uri'
    require 'uri'
    require 'json'
    require 'yaml'
    require 'sequel'

    Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

    require_relative '../config/constants'
    require_relative '../lib/annuaire_wrapper'
    require_relative '../lib/pronote'
    require_relative '../config/database'
    require_relative '../models/models'
  end

  desc 'Open pry with app environment'
  task pry: :load_config do
    pry.binding
  end
end
