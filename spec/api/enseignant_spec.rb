# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods

  before :all do
    db_cleaner = TableCleaner.new DB, []
    db_cleaner.clean

    # FIXME: something faster
    xml_filename = 'spec/fixtures/Edt_To_LaclasseCom_0134567A_Enclair.xml'
    post '/pronote/xml', xml_file: Rack::Test::UploadedFile.new(xml_filename, 'text/xml')

    require_relative '../fixtures/insertion-test-data.rb'
  end

  def app
    CahierDeTextesAPI::API
  end

  ############ POST ############
  it 'creates a new cours' do
    cahier_de_textes_id = CahierDeTextes.all[ rand(0 .. CahierDeTextes.count - 1) ][:id]
    creneau_emploi_du_temps_id = CreneauEmploiDuTemps.all[ rand(0 .. CreneauEmploiDuTemps.count - 1) ][:id]

    post( '/enseignant/cours',
          { cahier_de_textes_id: cahier_de_textes_id,
            creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
            date_cours: '2013-08-29',
            contenu: 'Exemple de séquence pédagogique.'}.to_json,
          'CONTENT_TYPE' => 'application/json' )
    last_response.status.should == 201

    cours = Cours.last
    cours.cahier_de_textes_id.should == cahier_de_textes_id
    cours.creneau_emploi_du_temps_id.should == creneau_emploi_du_temps_id
    cours.date_cours.should == Date.parse('2013-08-29')
    cours.date_creation.should_not equal nil
    cours.date_modification.should equal nil
    cours.date_validation.should equal nil
    cours.contenu.should == 'Exemple de séquence pédagogique.'
    cours.deleted.should equal false
  end

  ############ PUT ############
  it 'updates a cours' do
    cours = Cours.last

    put( "/enseignant/cours/#{cours.id}",
         { contenu: 'Mise à jour de la séquence pédagogique.'}.to_json,
         'CONTENT_TYPE' => 'application/json' )
    last_response.status.should == 200

    cours2 = Cours[ cours.id ]

    cours2.cahier_de_textes_id.should == cours.cahier_de_textes_id
    cours2.creneau_emploi_du_temps_id.should == cours.creneau_emploi_du_temps_id
    cours2.date_cours.should == cours.date_cours
    cours2.date_creation.should == cours.date_creation
    cours2.date_modification.should_not equal nil
    cours2.date_modification.should be > cours.date_modification unless cours.date_modification.nil?
    cours2.date_validation.should == cours.date_validation
    cours2.contenu.should == 'Mise à jour de la séquence pédagogique.'
    cours2.deleted.should == cours.deleted
  end

  ############ GET ############
  it 'gets the details of a cours' do
    cours = Cours.last

    get "/enseignant/cours/#{cours.id}"
    last_response.status.should == 200

    response_body = JSON.parse(last_response.body)

    response_body['cahier_de_textes_id'].should == cours.cahier_de_textes_id
    response_body['creneau_emploi_du_temps_id'].should == cours.creneau_emploi_du_temps_id
    response_body['date_cours'].should == cours.date_cours.to_s
    # response_body['date_creation'].should == cours.date_creation ? cours.date_creation.to_s : nil
    # response_body['date_modification'].should == cours.date_modification ? cours.date_modification.to_s : nil
    # response_body['date_validation'].should == cours.date_validation ? cours.date_validation.to_s : nil
    response_body['date_creation'].should_not equal nil
    response_body['contenu'].should == cours.contenu
    response_body['deleted'].should == cours.deleted
  end

  ############ DELETE ############
  it 'deletes a cours' do
    cours = Cours.last
    cours.deleted.should be_false

    delete "/enseignant/cours/#{cours.id}"

    cours = Cours.last
    cours.deleted.should be_true

    get "/enseignant/cours/#{cours.id}"
    last_response.status.should == 404
  end
end
