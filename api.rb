# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'

Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

require 'laclasse/helpers/authentication'
require 'laclasse/helpers/user'

require_relative './models/models'
require_relative './lib/data_management'
require_relative './lib/pronote'

require_relative './api/users'

require_relative './api/import'
require_relative './api/matchable'
require_relative './api/etablissements'
require_relative './api/cours'
require_relative './api/devoirs'
require_relative './api/types_de_devoir'
require_relative './api/emplois_du_temps'
require_relative './api/creneaux_emploi_du_temps'
require_relative './api/salles'
require_relative './api/cahiers_de_textes'

require_relative './api/stats'

module CahierDeTextesApp
  class API < Grape::API
    format :json
    rescue_from Grape::Exceptions::ValidationErrors do |e|
      error!({ messages: e.full_messages }, 400)
    end

    helpers Laclasse::Helpers::Authentication
    helpers Laclasse::Helpers::User

    before do
      error!( '401 Unauthorized', 401 ) unless logged? || !request.env['PATH_INFO'].match(/.*swagger.*\.json$/).nil?

      DataManagement::Provisioning.provision( user )
    end

    resource( :users                    ) { mount ::CahierDeTextesApp::UsersAPI }

    resource( :import                   ) do
      mount ::CahierDeTextesApp::ImportAPI
      resource( :matchable                ) { mount ::CahierDeTextesApp::MatchableAPI }
    end

    resource( :etablissements           ) { mount ::CahierDeTextesApp::EtablissementsAPI }
    resource( :cours                    ) { mount ::CahierDeTextesApp::CoursAPI }
    resource( :devoirs                  ) { mount ::CahierDeTextesApp::DevoirsAPI }
    resource( :types_de_devoir          ) { mount ::CahierDeTextesApp::TypesDeDevoirAPI }
    resource( :emplois_du_temps         ) { mount ::CahierDeTextesApp::EmploisDuTempsAPI }
    resource( :creneaux_emploi_du_temps ) { mount ::CahierDeTextesApp::CreneauxEmploiDuTempsAPI }
    resource( :salles                   ) { mount ::CahierDeTextesApp::SallesAPI }
    resource( :cahiers_de_textes        ) { mount ::CahierDeTextesApp::CahiersDeTextesAPI }

    resource( :stats                    ) { mount ::CahierDeTextesApp::StatsAPI }
  end
end
