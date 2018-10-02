# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::AttachmentTypes' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    it 'gets all attachment types' do
        get '/api/attachment_types/'

        body = JSON.parse( last_response.body )

        expect( body.length ).to eq AttachmentType.count
    end

    it 'gets a specific attachment type by id' do
        get '/api/attachment_types/1'
        body = JSON.parse( last_response.body )

        expect( body['id'] ).to eq 1
        expect( body['description'] ).to eq AttachmentType[id: 1].description
    end
end
