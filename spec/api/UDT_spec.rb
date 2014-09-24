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

  # it 'uploads a file' do
  #   xml_filename = 'spec/fixtures/UDT.zip'
  #   uai = '0987654W'
  #   post "/v1/import/udt/uai/#{uai}", file: Rack::Test::UploadedFile.new(xml_filename, 'text/xml')
  #   expect( last_response.status ).to eq 201
  # end

end
