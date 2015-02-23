# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::V1::UsersAPI do
  include Rack::Test::Methods

  def app
    CahierDeTextesAPI::API
  end

  before :all do
    module Laclasse
      module Helpers
        module Authentication
          def logged?
            LOGGER.info 'Yeah yeah you are logged *wink*'
            true
          end
        end
      end
    end

    module CahierDeTextesApp
      module Helpers
        module User
          def user_needs_to_be( profils_ids, admin )
            LOGGER.info "MOCKED user_needs_to_be( #{profils_ids}, #{admin} )"
          end
        end
      end
    end
  end

  # Tests proprement dit
  it 'links a failed identification to an Annuaire\'s ID' do

    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { uid: 'VAA00000',
              user_detailed: { 'classes' => [ { 'etablissement_code' => 'Test',
                                                'classe_id' => 1 },
                                              { 'etablissement_code' => 'Test',
                                                'classe_id' => 2 },
                                              { 'etablissement_code' => 'Invalid',
                                                'classe_id' => 9 } ],
                               'groupes_eleves' => [ { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 11 },
                                                     { 'etablissement_code' => 'Invalid',
                                                       'groupe_id' => 99 },
                                                     { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 12 } ],
                               'groupes_libres' => [ { 'etablissement_code' => 'Invalid',
                                                       'groupe_id' => 999 },
                                                     { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 101 },
                                                     { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 102 } ],
                               'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'TECH' } ],
                               'profils' => [ { 'etablissement_code_uai' => 'Test',
                                                'profil_id' => 'ENS' },
                                              { 'etablissement_code_uai' => 'Invalid',
                                                'profil_id' => 'DIR' } ],
                               'profil_actif' => { 'etablissement_code_uai' => 'Test',
                                                   'profil_id' => 'ENS' },
                               'etablissements' => 'dummy',
                               'applications' => 'dummy',
                               'ressources_numeriques' => 'dummy',
                               'enfants' => 'dummy',
                             } }
          end
        end
      end
    end

    get '/v1/users/current'

    LOGGER.debug last_response if last_response.status == 500
    expect( last_response.status ).to eq 200

    response = JSON.parse last_response.body
    expect( response['uid'] ).to eq 'VAA00000'

    expect( response['classes'].count ).to eq 9
    expect( response['classes'].select { |r| r['type'] == 'classe' }.count ).to eq 3
    expect( response['classes'].select { |r| r['type'] == 'groupe' }.count ).to eq 6
    expect( response['profils'].count ).to eq 2
    expect( response['profil_actif']['profil_id'] ).to eq 'ENS'
    expect( response['profil_actif']['etablissement_code_uai'] ).to eq 'Test'
    expect( response['enfants'] ).to eq 'dummy'
    expect( response['parametrage_cahier_de_textes'].count ).to eq 2
    expect( response['parametrage_cahier_de_textes']['affichage_types_de_devoir'] ).to be true
    expect( response['parametrage_cahier_de_textes']['affichage_week_ends'] ).to be false
  end
end
