# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler'

Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

require_relative './lib/AuthenticationHelpers'
require_relative './lib/UserHelpers'

require_relative './models/models'
require_relative './lib/pronote'

require_relative './api/users'

require_relative './api/pronote'
require_relative './api/etablissements'
require_relative './api/cours'
require_relative './api/devoirs'
require_relative './api/types_de_devoir'
require_relative './api/emplois_du_temps'
require_relative './api/cahiers_de_textes'
require_relative './api/annuaire'
require_relative './api/creneaux_emploi_du_temps'
require_relative './api/plages_horaires'

module CahierDeTextesAPI
  class API < Grape::API
    version 'v0', using: :path, vendor: 'laclasse.com'
    format :json
    rescue_from :all

    helpers AuthenticationHelpers
    helpers UserHelpers

    before do
      error!( '401 Unauthorized', 401 ) unless is_logged?
    end

    resource( :users                    ) { mount ::CahierDeTextesAPI::UsersAPI }

    resource( :pronote                  ) { mount ::CahierDeTextesAPI::ProNoteAPI }
    resource( :etablissements           ) { mount ::CahierDeTextesAPI::EtablissementsAPI }
    resource( :cours                    ) { mount ::CahierDeTextesAPI::CoursAPI }
    resource( :devoirs                  ) { mount ::CahierDeTextesAPI::DevoirsAPI }
    resource( :types_de_devoir          ) { mount ::CahierDeTextesAPI::TypesDeDevoirAPI }
    resource( :emplois_du_temps         ) { mount ::CahierDeTextesAPI::EmploisDuTempsAPI }
    resource( :cahiers_de_textes        ) { mount ::CahierDeTextesAPI::CahiersDeTextesAPI }
    resource( :annuaire                 ) { mount ::CahierDeTextesAPI::AnnuaireAPI }
    resource( :creneaux_emploi_du_temps ) { mount ::CahierDeTextesAPI::CreneauxEmploiDuTempsAPI }
    resource( :plages_horaires          ) { mount ::CahierDeTextesAPI::PlagesHorairesAPI }

    add_swagger_documentation api_version: 'v0'
  end
end
