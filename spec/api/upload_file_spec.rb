require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods

  # before(:all) do
  #   DB.tables.each do |table|
  #     DB.drop_table?(table, cascade: true)
  #   end
  # end
  
  def app
    CahierDeTextesAPI::API
  end

  it "uploads a file" do
    xml_filename = "spec/fixtures/Edt_To_LaclasseCom_0134567A_Enclair.xml"
    post "/pronote/upload_xml", :xml_file => Rack::Test::UploadedFile.new(xml_filename, 'text/xml')
    last_response.status.should == 201
    last_response.body.should == {
      "filename" => "Edt_To_LaclasseCom_0134567A_Enclair.xml",
      "size" => File.size(xml_filename),
      "nb_salles" => 24,
      "nb_plages_horaires" => 20,
      "nb_creneau_emploi_du_temps" => 701,
    }.to_json
  end

end

