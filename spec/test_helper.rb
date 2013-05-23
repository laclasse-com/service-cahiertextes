#coding: utf-8
require 'rspec'
require 'rack/test'
require 'rubygems'
require 'simplecov'

############################################## 
# Définition de la couverture de simpleCov
############################################## 
SimpleCov.adapters.define 'laclasse' do
  add_filter '/config/'
  add_filter '/spec/'
  add_filter '/tasks/'

  add_group 'Api', 'api'
  add_group 'Configuration', 'config'
  add_group 'Libraries', 'lib'
  add_group 'Sequel models', 'model'
end

SimpleCov.start 'laclasse'

require_relative '../app'

APP_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..')) if !APP_ROOT


#
# Données de test
#
