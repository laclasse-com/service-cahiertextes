# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::V1::ImportAPI do
  include Rack::Test::Methods

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

  before :each do
    TableCleaner.new( DB, [] ).clean
  end

  def app
    CahierDeTextesAPI::API
  end

  # Tests proprement dit
  it 'links a failed identification to an Annuaire\'s ID' do
    sha256 = Digest::SHA256.hexdigest "test#{rand}"
    id_annuaire = 'test'
    FailedIdentification.create( sha256: sha256 )

    put "/v1/import/mrpni/#{sha256}/est/#{id_annuaire}",
        {}.to_json,
        'CONTENT_TYPE' => 'application/json'

    LOGGER.debug last_response if last_response.status == 500
    expect( last_response.status ).to eq 200

    body = JSON.parse( last_response.body )
    expect( body['sha256'] ).to eq sha256
    expect( body['id_annuaire'] ).to eq id_annuaire
  end

  it 'uploads and import a Pronote file' do

    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { uid: 'VAA00000',
              user_detailed: { 'etablissements' => [ { 'code_uai' => '0134567A',
                                                       'profils' => [ { 'profil_id' => 'DIR'
                                                                      } ]
                                                     } ]
                             } }
          end
        end
      end
    end

    if File.exist? PRONOTE[:cle_integrateur]
      xml_filename = 'spec/fixtures/Edt_To_LaclasseCom_0134567A.xml'
      post '/v1/import/pronote', file: Rack::Test::UploadedFile.new(xml_filename, 'text/xml')

      LOGGER.debug last_response if last_response.status == 500
      expect( last_response.status ).to eq 201

      expect( CahierDeTextes.count ).to eq 0
      expect( Cours.count ).to eq 0
      expect( CoursRessource.count ).to eq 0
      # expect( CreneauEmploiDuTemps.count ).to eq 285
      # expect( CreneauEmploiDuTempsEnseignant.count ).to eq 0
      # expect( CreneauEmploiDuTempsRegroupement.count ).to eq 0
      # expect( CreneauEmploiDuTempsSalle.count ).to eq 382
      # expect( DevoirTodoItem.count ).to eq 0
      # expect( Devoir.count ).to eq 0
      # expect( DevoirRessource .count ).to eq 0
      # expect( Etablissement.count ).to eq 1
      # expect( FailedIdentification.count ).to eq 104
      # expect( PlageHoraire.count ).to eq 20
      # expect( Ressource.count ).to eq 0
      # expect( Salle.count ).to eq 24
      # expect( TypeDevoir.count ).to eq 0
      # expect( UserParameters.count ).to eq 0

      # CreneauEmploiDuTempsRegroupement
      #   .all
      #   .map { |r| r.regroupement_id }
      #   .uniq
      #   .sort
      #   .each do |regroupement_id|
      #   expect( CahierDeTextes.where( regroupement_id: regroupement_id ).count ).to eq 1
      # end
    else
      STDERR.puts 'Impossible de tester sans la clef privée'
      expect( true ).to eq true
    end
  end
end
