# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::Trails' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    itid = nil

    it 'gets all trails' do
        get '/api/trails/'

        body = JSON.parse( last_response.body )

        expect( body.length ).to eq Trail.count
    end

    it 'gets a specific trail by id' do
        get '/api/trails/1'
        body = JSON.parse( last_response.body )

        expect( body['id'] ).to eq 1
        expect( body['label'] ).to eq Trail[id: 1].label
    end

    it 'FORBIDS creation when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        post '/api/trails/', label: 'test'

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'creates a trail' do
        nb_trails_before = Trail.count
        label = "test #{Time.now}"

        post '/api/trails/', label: label

        body = JSON.parse( last_response.body )
        itid = body['id']

        expect( Trail.count ).to eq nb_trails_before + 1
        expect( body['label'] ).to eq label

        #Trail[id: body['id']]&.destroy
    end

    it 'FORBIDS update when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        put "/api/trails/#{itid}", label: 'test2'

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'updates the label' do
        put "/api/trails/#{itid}", label: 'test2'

        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq 'test2'
    end

    it 'FORBIDS deletion when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        delete "/api/trails/#{itid}"

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'deletes a trail' do
        nb_trails_before = Trail.count

        delete "/api/trails/#{itid}"

        expect( Trail.count ).to eq nb_trails_before - 1
        expect( last_response.body ).to eq ''
    end
end
