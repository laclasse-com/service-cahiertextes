# -*- coding: utf-8 -*-

require_relative './users'

require_relative './import'
require_relative './matchable'
require_relative './etablissements'
require_relative './cours'
require_relative './devoirs'
require_relative './types_de_devoir'
require_relative './emplois_du_temps'
require_relative './annuaire'
require_relative './creneaux_emploi_du_temps'
require_relative './salles'
require_relative './cahiers_de_textes'

module CahierDeTextesAPI
  module V1
    class API < Grape::API
      format :json
      rescue_from Grape::Exceptions::ValidationErrors do |e|
        error!({ messages: e.full_messages }, 400)
      end

      resource( :users                    ) { mount ::CahierDeTextesAPI::UsersAPI }

      resource( :import                   ) do
        mount ::CahierDeTextesAPI::ImportAPI
        resource( :matchable                ) { mount ::CahierDeTextesAPI::MatchableAPI }
      end

      resource( :annuaire                 ) { mount ::CahierDeTextesAPI::AnnuaireAPI }

      resource( :etablissements           ) { mount ::CahierDeTextesAPI::EtablissementsAPI }
      resource( :cours                    ) { mount ::CahierDeTextesAPI::CoursAPI }
      resource( :devoirs                  ) { mount ::CahierDeTextesAPI::DevoirsAPI }
      resource( :types_de_devoir          ) { mount ::CahierDeTextesAPI::TypesDeDevoirAPI }
      resource( :emplois_du_temps         ) { mount ::CahierDeTextesAPI::EmploisDuTempsAPI }
      resource( :creneaux_emploi_du_temps ) { mount ::CahierDeTextesAPI::CreneauxEmploiDuTempsAPI }
      resource( :salles                   ) { mount ::CahierDeTextesAPI::SallesAPI }
      resource( :cahiers_de_textes        ) { mount ::CahierDeTextesAPI::CahiersDeTextesAPI }
    end
  end
end
