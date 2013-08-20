#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'

require 'nokogiri'
require 'sequel'
require 'sequel/extensions/migration'

require './models'
require './pronote'

load_ProNote_XML( File.open( "mocks/Edt_To_LaclasseCom_0134567A_Enclair.xml" ),
                  File.open( "mocks/ExportEmploiDuTemps.xsd" ) )
