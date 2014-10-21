# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
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

    # Mock d'une session Élève
    module UserHelpers
      def user
        HashedUser.new( MOCKED_DATA[:users][:principal][:rack_session] )
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
    xml_filename = 'spec/fixtures/Edt_To_LaclasseCom_0134567A.xml'
    post '/v1/import/pronote', file: Rack::Test::UploadedFile.new(xml_filename, 'text/xml')

    expect( last_response.status ).to eq 201

    expect( CahierDeTextes.count ).to eq 0
    expect( Cours.count ).to eq 0
    expect( CoursRessource.count ).to eq 0
    expect( CreneauEmploiDuTemps.count ).to eq 512
    expect( CreneauEmploiDuTempsEnseignant.count ).to eq 0
    expect( CreneauEmploiDuTempsRegroupement.count ).to eq 0
    expect( CreneauEmploiDuTempsSalle.count ).to eq 410
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

  end
end
