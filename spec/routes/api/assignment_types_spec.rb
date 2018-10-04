# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::AssignmentTypes' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    atid = nil

    it 'gets all assignment types' do
        get '/api/assignment_types/'

        body = JSON.parse( last_response.body )

        expect( body.length ).to eq AssignmentType.count
    end

    it 'gets a specific assignment type by id' do
        get '/api/assignment_types/1'
        body = JSON.parse( last_response.body )

        expect( body['id'] ).to eq 1
        expect( body['description'] ).to eq AssignmentType[id: 1].description
    end

    it 'FORBIDS creation when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        post '/api/assignment_types/', label: 'test'

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'creates an assignment type with just a label' do
        nb_types_before = AssignmentType.count

        post '/api/assignment_types/', label: 'test'

        body = JSON.parse( last_response.body )

        expect( AssignmentType.count ).to eq nb_types_before + 1
        expect( body['label'] ).to eq 'test'
        expect( body['description'] ).to be nil

        AssignmentType[id: body['id']]&.destroy
    end

    it 'creates an assignment type with a label and a description' do
        nb_types_before = AssignmentType.count

        post '/api/assignment_types/', label: 'test', description: 'description'

        body = JSON.parse( last_response.body )

        atid = body['id']

        expect( AssignmentType.count ).to eq nb_types_before + 1
        expect( body['label'] ).to eq 'test'
        expect( body['description'] ).to eq 'description'
    end

    it 'FORBIDS update when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        put "/api/assignment_types/#{atid}", label: 'test2'

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'updates the label' do
        put "/api/assignment_types/#{atid}", label: 'test2'

        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq 'test2'
        expect( body['description'] ).to eq 'description'
    end

    it 'updates the description' do
        put "/api/assignment_types/#{atid}", description: 'description2'

        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq 'test2'
        expect( body['description'] ).to eq 'description2'
    end

    it 'updates the label and description' do
        put "/api/assignment_types/#{atid}", label: 'test3', description: 'description3'

        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq 'test3'
        expect( body['description'] ).to eq 'description3'
    end

    it 'FORBIDS deletion when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        delete "/api/assignment_types/#{atid}"

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'deletes an assignment type' do
        nb_types_before = AssignmentType.count

        delete "/api/assignment_types/#{atid}"

        expect( AssignmentType.count ).to eq nb_types_before - 1
        expect( last_response.body ).to eq ''
    end
end
