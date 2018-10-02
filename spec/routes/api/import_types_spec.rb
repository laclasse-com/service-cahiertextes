# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::ImportTypes' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    it 'gets all import types' do
        get '/api/import_types/'

        body = JSON.parse( last_response.body )

        expect( body.length ).to eq ImportType.count
    end

    it 'gets a specific import type by id' do
        get '/api/import_types/1'
        body = JSON.parse( last_response.body )

        expect( body['id'] ).to eq 1
        expect( body['description'] ).to eq ImportType[id: 1].description
    end
end
