# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods

  before :each do
    db_cleaner = TableCleaner.new DB, []
    db_cleaner.clean
  end

  def app
    CahierDeTextesAPI::API
  end

  it 'uploads a file' do
    xml_filename = 'spec/fixtures/Edt_To_LaclasseCom_0134567A.xml'
    post '/v1/import/pronote', file: Rack::Test::UploadedFile.new(xml_filename, 'text/xml')

    expect( last_response.status ).to eq 201

    CreneauEmploiDuTempsRegroupement
      .select(:regroupement_id)
      .map { |r| r.regroupement_id }
      .uniq
      .sort
      .each { |regroupement_id|
      expect( CahierDeTextes.where( regroupement_id: regroupement_id ).count ).to eq 1
    }
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
