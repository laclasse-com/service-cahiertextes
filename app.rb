# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'

require 'grape'
require 'nokogiri'
require 'sequel'
require 'sequel/extensions/migration'

require_relative './models/models'
require_relative './lib/pronote'

require_relative './api/pronote'
require_relative './api/principal'

require_relative './api/cours'
require_relative './api/devoir'
require_relative './api/emploi_du_temps'
require_relative './api/cahier_de_textes'

module CahierDeTextesAPI
  class API < Grape::API
    version 'v0', using: :header, vendor: 'laclasse.com'
    format :json
    rescue_from :all

    helpers do
      def current_user
        # TODO: @current_user ||= User.authorize!(env)
        true
      end

      def authenticate!
        error!('401 Unauthorized', 401) unless current_user
      end
    end

    mount ::CahierDeTextesAPI::ProNoteAPI
    mount ::CahierDeTextesAPI::EtablissementAPI

    mount ::CahierDeTextesAPI::CoursAPI
    mount ::CahierDeTextesAPI::DevoirAPI
    mount ::CahierDeTextesAPI::EmploiDuTempsAPI
    mount ::CahierDeTextesAPI::CahierDeTextesAPI

  end
end
