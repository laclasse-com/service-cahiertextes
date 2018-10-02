# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::ResourceTypes' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    it 'gets all resource types' do
        get '/api/resource_types/'

        body = JSON.parse( last_response.body )

        expect( body.length ).to eq ResourceType.count
    end

    it 'gets a specific resource type by id' do
        get '/api/resource_types/1'
        body = JSON.parse( last_response.body )

        expect( body['id'] ).to eq 1
        expect( body['description'] ).to eq ResourceType[id: 1].description
    end
end
