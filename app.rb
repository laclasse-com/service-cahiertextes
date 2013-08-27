# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'

require 'grape'
require 'nokogiri'
require 'sequel'
require 'sequel/extensions/migration'

require_relative './models/models'
require_relative './lib/pronote'

require_relative './api/etablissement'

module CahierDeTextesAPI
  class API < Grape::API
    version 'v0', using: :header, vendor: 'laclasse.com'
    format :json

    helpers do
      def current_user
        # TODO: @current_user ||= User.authorize!(env)
        true
      end

      def authenticate!
        error!('401 Unauthorized', 401) unless current_user
      end
    end

    mount ::CahierDeTextesAPI::Etablissement

  end
end

ProNote.decrypt_XML(File.open('mocks/Edt_To_LaclasseCom_0134567A.xml'),
                    File.open('mocks/ConteneurExportChiffre.xsd'))
ProNote.load_XML(File.open('mocks/Edt_To_LaclasseCom_0134567A_Enclair.xml'),
                 File.open('mocks/ExportEmploiDuTemps.xsd'))
