# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::AttachmentTypes' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    atid = nil

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

    it 'FORBIDS creation when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        post '/api/attachment_types/', label: 'test'

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'creates an attachment type with just a label' do
        nb_types_before = AttachmentType.count

        post '/api/attachment_types/', label: 'test'

        body = JSON.parse( last_response.body )

        expect( AttachmentType.count ).to eq nb_types_before + 1
        expect( body['label'] ).to eq 'test'
        expect( body['description'] ).to be nil

        AttachmentType[id: body['id']]&.destroy
    end

    it 'creates an attachment type with a label and a description' do
        nb_types_before = AttachmentType.count

        post '/api/attachment_types/', label: 'test', description: 'description'

        body = JSON.parse( last_response.body )

        atid = body['id']

        expect( AttachmentType.count ).to eq nb_types_before + 1
        expect( body['label'] ).to eq 'test'
        expect( body['description'] ).to eq 'description'
    end

    it 'FORBIDS update when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        put "/api/attachment_types/#{atid}", label: 'test2'

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'updates the label' do
        put "/api/attachment_types/#{atid}", label: 'test2'

        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq 'test2'
        expect( body['description'] ).to eq 'description'
    end

    it 'updates the description' do
        put "/api/attachment_types/#{atid}", description: 'description2'

        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq 'test2'
        expect( body['description'] ).to eq 'description2'
    end

    it 'updates the label and description' do
        put "/api/attachment_types/#{atid}", label: 'test3', description: 'description3'

        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq 'test3'
        expect( body['description'] ).to eq 'description3'
    end

    it 'FORBIDS deletion when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        delete "/api/attachment_types/#{atid}"

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'deletes an attachment type' do
        nb_types_before = AttachmentType.count

        delete "/api/attachment_types/#{atid}"

        expect( AttachmentType.count ).to eq nb_types_before - 1
        expect( last_response.body ).to eq ''
    end
end
