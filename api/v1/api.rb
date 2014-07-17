# -*- coding: utf-8 -*-

require_relative './users'

require_relative './pronote'
require_relative './etablissements'
require_relative './cours'
require_relative './devoirs'
require_relative './types_de_devoir'
require_relative './emplois_du_temps'
require_relative './annuaire'
require_relative './creneaux_emploi_du_temps'
require_relative './plages_horaires'
require_relative './cahiers_de_textes'

module CahierDeTextesAPI
   module V1
      class API < Grape::API
         version 'v1', using: :path, vendor: 'laclasse.com'
         format :json
         rescue_from :all

         resource( :users                    ) { mount ::CahierDeTextesAPI::V1::UsersAPI }

         resource( :pronote                  ) { mount ::CahierDeTextesAPI::V1::ProNoteAPI }
         resource( :etablissements           ) { mount ::CahierDeTextesAPI::V1::EtablissementsAPI }
         resource( :cours                    ) { mount ::CahierDeTextesAPI::V1::CoursAPI }
         resource( :devoirs                  ) { mount ::CahierDeTextesAPI::V1::DevoirsAPI }
         resource( :types_de_devoir          ) { mount ::CahierDeTextesAPI::V1::TypesDeDevoirAPI }
         resource( :emplois_du_temps         ) { mount ::CahierDeTextesAPI::V1::EmploisDuTempsAPI }
         resource( :annuaire                 ) { mount ::CahierDeTextesAPI::V1::AnnuaireAPI }
         resource( :creneaux_emploi_du_temps ) { mount ::CahierDeTextesAPI::V1::CreneauxEmploiDuTempsAPI }
         resource( :plages_horaires          ) { mount ::CahierDeTextesAPI::V1::PlagesHorairesAPI }
         resource( :cahiers_de_textes        ) { mount ::CahierDeTextesAPI::V1::CahiersDeTextesAPI }

         add_swagger_documentation base_path: "#{APP_PATH}/api",
            api_version: 'v1',
            hide_documentation_path: true
      end
   end
end
