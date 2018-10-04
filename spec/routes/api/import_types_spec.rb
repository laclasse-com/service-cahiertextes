# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::ImportTypes' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    itid = nil

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

    it 'FORBIDS creation when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        post '/api/import_types/', label: 'test'

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'creates an import type with just a label' do
        nb_types_before = ImportType.count

        post '/api/import_types/', label: 'test'

        body = JSON.parse( last_response.body )

        expect( ImportType.count ).to eq nb_types_before + 1
        expect( body['label'] ).to eq 'test'
        expect( body['description'] ).to be nil

        ImportType[id: body['id']]&.destroy
    end

    it 'creates an import type with a label and a description' do
        nb_types_before = ImportType.count

        post '/api/import_types/', label: 'test', description: 'description'

        body = JSON.parse( last_response.body )

        itid = body['id']

        expect( ImportType.count ).to eq nb_types_before + 1
        expect( body['label'] ).to eq 'test'
        expect( body['description'] ).to eq 'description'
    end

    it 'FORBIDS update when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        put "/api/import_types/#{itid}", label: 'test2'

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'updates the label' do
        put "/api/import_types/#{itid}", label: 'test2'

        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq 'test2'
        expect( body['description'] ).to eq 'description'
    end

    it 'updates the description' do
        put "/api/import_types/#{itid}", description: 'description2'

        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq 'test2'
        expect( body['description'] ).to eq 'description2'
    end

    it 'updates the label and description' do
        put "/api/import_types/#{itid}", label: 'test3', description: 'description3'

        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq 'test3'
        expect( body['description'] ).to eq 'description3'
    end

    it 'FORBIDS deletion when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        delete "/api/import_types/#{itid}"

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'deletes an import type' do
        nb_types_before = ImportType.count

        delete "/api/import_types/#{itid}"

        expect( ImportType.count ).to eq nb_types_before - 1
        expect( last_response.body ).to eq ''
    end
end
