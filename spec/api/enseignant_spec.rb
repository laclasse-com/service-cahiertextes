# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods
  
  def app
    CahierDeTextesAPI::API
  end

  it "posts a new séquence pédagogique" do
    post "/enseignant/cours", cahier_de_textes_id: 1, creneau_emploi_du_temps_id: 2, date_cours: "2013-08-29 17:24:54 +0200", contenu: "test de contenu\nallo"
    last_response.status.should == 201
    # last_response.body.should == {
    #   "filename" => "Edt_To_LaclasseCom_0134567A_Enclair.xml",
    #   "size" => File.size(xml_filename),
    #   "nb_salles" => 24,
    #   "nb_plages_horaires" => 20,
    #   "nb_creneau_emploi_du_temps" => 701,
    # }.to_json
  end

end

