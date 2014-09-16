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
    post '/v0/pronote/xml', file: Rack::Test::UploadedFile.new(xml_filename, 'text/xml')
    last_response.status.should == 201

    last_response.body.should == {
      'filename' => 'Edt_To_LaclasseCom_0134567A.xml',
      'size' => File.size(xml_filename),
      'nb_salles' => 24,
      'nb_plages_horaires' => 20,
      # 'nb_creneau_emploi_du_temps' => 701,
      'nb_creneau_emploi_du_temps' => 512, # compense les matières inconnues
    }.to_json

    CreneauEmploiDuTempsRegroupement
      .select(:regroupement_id)
      .map { |r| r.regroupement_id }
      .uniq
      .sort
      .each { |regroupement_id|
      CahierDeTextes.where( regroupement_id: regroupement_id ).count.should == 1
    }
  end

  it 'links a failed identification to an Annuaire\'s ID' do
    sha256 = Digest::SHA256.hexdigest "test#{rand}"
    id_annuaire = 'test'
    FailedIdentification.create( sha256: sha256 )

    put "/v1/import/mrpni/#{sha256}/est/#{id_annuaire}",
        {}.to_json,
        'CONTENT_TYPE' => 'application/json'

    last_response.status.should == 200

    body = JSON.parse( last_response.body )
    body['sha256'].should == sha256
    body['id_annuaire'].should == id_annuaire
  end
end
