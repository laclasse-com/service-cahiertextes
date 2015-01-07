# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::V1::ImportAPI do
  include Rack::Test::Methods

  before :all do
    module Annuaire
      module_function

      def get_user( _uid )
        MOCKED_DATA[:users][:principal][:annuaire]
      end

      def get_user_regroupements( uid )
        u = get_user( uid )
        { 'classes' => u['classes'],
          'groupes_eleves' => u['groupes_eleves'],
          'groupes_libres' => u['groupes_libres']
        }
      end

      def get_etablissement_regroupements( _uai )
        MOCKED_DATA[:etablissement][:regroupements]
      end
    end

    # Mock d'une session Principal
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            HashedUser.new( MOCKED_DATA[:users][:principal][:rack_session] )
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

  it 'uploads and import a Pronote file' do
    if File.exist? PRONOTE[:cle_integrateur]
      xml_filename = 'spec/fixtures/Edt_To_LaclasseCom_0134567A.xml'
      post '/v1/import/pronote', file: Rack::Test::UploadedFile.new(xml_filename, 'text/xml')

      expect( last_response.status ).to eq 201

      expect( CahierDeTextes.count ).to eq 0
      expect( Cours.count ).to eq 0
      expect( CoursRessource.count ).to eq 0
      expect( CreneauEmploiDuTemps.count ).to eq 285
      expect( CreneauEmploiDuTempsEnseignant.count ).to eq 0
      expect( CreneauEmploiDuTempsRegroupement.count ).to eq 0
      expect( CreneauEmploiDuTempsSalle.count ).to eq 382
      expect( DevoirTodoItem.count ).to eq 0
      expect( Devoir.count ).to eq 0
      expect( DevoirRessource .count ).to eq 0
      expect( Etablissement.count ).to eq 1
      expect( FailedIdentification.count ).to eq 104
      expect( PlageHoraire.count ).to eq 20
      expect( Ressource.count ).to eq 0
      expect( Salle.count ).to eq 24
      expect( TypeDevoir.count ).to eq 0
      expect( UserParameters.count ).to eq 0

      CreneauEmploiDuTempsRegroupement
        .all
        .map { |r| r.regroupement_id }
        .uniq
        .sort
        .each do |regroupement_id|
        expect( CahierDeTextes.where( regroupement_id: regroupement_id ).count ).to eq 1
      end
    else
      STDERR.puts 'Impossible de tester sans la clef privée'
      expect( true ).to eq true
    end
  end

  it 'links a failed identification to an Annuaire\'s ID' do
    sha256 = Digest::SHA256.hexdigest "test#{rand}"
    id_annuaire = 'test'
    FailedIdentification.create( sha256: sha256 )

    put "/v1/import/mrpni/#{sha256}/est/#{id_annuaire}",
        {}.to_json,
        'CONTENT_TYPE' => 'application/json'

    expect( last_response.status ).to eq 200

    body = JSON.parse( last_response.body )
    expect( body['sha256'] ).to eq sha256
    expect( body['id_annuaire'] ).to eq id_annuaire
  end
end
