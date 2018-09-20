# frozen_string_literal: true

source 'https://rubygems.org'

gem 'activesupport'
gem 'icalendar'
gem 'mysql2'
gem 'nokogiri'
gem 'pry'
gem 'puma'
gem 'rack'
gem 'rest-client'
gem 'rubyzip'
gem 'sequel'
gem 'sinatra'
gem 'sinatra-contrib'
gem 'sinatra-param'
gem 'xml-simple'

group :development do
    gem 'equivalent-xml'
    gem 'rack-test'
    gem 'reek'
    gem 'rspec'
    gem 'rubocop'
end
