# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::ResourceTypes' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    rtid = nil

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

    it 'FORBIDS creation when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars
        label = "test #{Time.now}"

        post '/api/resource_types/', resource_types: [ { label: label } ]

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'creates an resource type with just a label' do
        nb_types_before = ResourceType.count
        label = "test #{Time.now}"

        post '/api/resource_types/', resource_types: [ { label: label } ]

        body = JSON.parse( last_response.body )

        expect( ResourceType.count ).to eq nb_types_before + 1
        expect( body.first['label'] ).to eq label
        expect( body.first['description'] ).to be nil

        ResourceType[id: body.first['id']]&.destroy
    end

    it 'creates an resource type with a label and a description' do
        nb_types_before = ResourceType.count
        label = "test #{Time.now}"

        post '/api/resource_types/', resource_types: [ { label: label, description: 'description' } ]

        body = JSON.parse( last_response.body )
        rtid = body.first['id']

        expect( ResourceType.count ).to eq nb_types_before + 1
        expect( body.first['label'] ).to eq label
        expect( body.first['description'] ).to eq 'description'
    end

    it 'FORBIDS update when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        put "/api/resource_types/#{rtid}", label: 'test2'

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'updates the label' do
        put "/api/resource_types/#{rtid}", label: 'test2'

        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq 'test2'
        expect( body['description'] ).to eq 'description'
    end

    it 'updates the description' do
        put "/api/resource_types/#{rtid}", description: 'description2'

        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq 'test2'
        expect( body['description'] ).to eq 'description2'
    end

    it 'updates the label and description' do
        put "/api/resource_types/#{rtid}", label: 'test3', description: 'description3'

        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq 'test3'
        expect( body['description'] ).to eq 'description3'
    end

    it 'FORBIDS deletion when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        delete "/api/resource_types/#{rtid}"

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'deletes an resource type' do
        nb_types_before = ResourceType.count

        delete "/api/resource_types/#{rtid}"

        expect( ResourceType.count ).to eq nb_types_before - 1
        expect( last_response.body ).to eq ''
    end
end
