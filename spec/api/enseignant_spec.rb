# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods

  before :each do
    db_cleaner = TableCleaner.new DB, []
    db_cleaner.clean

    xml_filename = "spec/fixtures/Edt_To_LaclasseCom_0134567A_Enclair.xml"
    post "/pronote/xml", :xml_file => Rack::Test::UploadedFile.new(xml_filename, 'text/xml')

    require_relative '../fixtures/insertion-test-data.rb'
  end

  def app
    CahierDeTextesAPI::API
  end

  it "posts a new séquence pédagogique" do
    cahier_de_textes_id = CahierDeTextes.all[ rand(0..CahierDeTextes.count-1) ][:id]
    creneau_emploi_du_temps_id = CreneauEmploiDuTemps.all[ rand(0..CreneauEmploiDuTemps.count-1) ][:id]
    post "/enseignant/cours", { cahier_de_textes_id: cahier_de_textes_id, creneau_emploi_du_temps_id: creneau_emploi_du_temps_id, date_cours: "2013-08-29", contenu: "test de contenu\nallo"}.to_json, "CONTENT_TYPE" => "application/json"
    last_response.status.should == 201

    # last_response.body.should == { cahier_de_textes_id: cahier_de_textes_id,
    #   creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
    #   date_cours: "2013-08-29",
    #   date_creation: nil,
    #   date_modification: nil,
    #   date_validation: nil,
    #   contenu: "test de contenu\nallo",
    #   deleted: false }.to_json
    response_body = JSON.parse(last_response.body)
    response_body["cahier_de_textes_id"].should ==  cahier_de_textes_id
    response_body["creneau_emploi_du_temps_id"].should == creneau_emploi_du_temps_id
    response_body["onsedate_cours"].should == "2013-08-29"
    response_body["onsedate_creation"].should == nil
    response_body["onsedate_modification"].should == nil
    response_body["onsedate_validation"].should == nil
    response_body["onsecontenu"].should == "test de contenu\nallo"
    response_body["onsedeleted"].should == false
  end

end
