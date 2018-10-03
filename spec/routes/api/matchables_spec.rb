# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::Matchables' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    MOCK_HASH = 'hash'
    MOCK_KNOWN_ID = 'known_id'

    it 'creates a Matchable' do
        post "/api/matchables/#{MOCK_UAI}/#{MOCK_HASH}", known_id: MOCK_KNOWN_ID

        body = JSON.parse( last_response.body )
        expect( body.length ).to eq Matchable.columns.count
        expect( body['hash_item'] ).to eq MOCK_HASH
        expect( body['known_id'] ).to eq MOCK_KNOWN_ID
        expect( body['structure_id'] ).to eq MOCK_UAI
    end

    it 'gets a Matchable by hash' do
        get "/api/matchables/#{MOCK_UAI}/#{MOCK_HASH}"

        body = JSON.parse( last_response.body )
        expect( body.length ).to eq Matchable.columns.count
        expect( body['hash_item'] ).to eq MOCK_HASH
        expect( body['known_id'] ).to eq MOCK_KNOWN_ID
        expect( body['structure_id'] ).to eq MOCK_UAI
    end

    it 'gets all Matchables of a structure' do
        get "/api/matchables/#{MOCK_UAI}"

        body = JSON.parse( last_response.body )
        expect( body.length ).to eq Matchable.where(structure_id: MOCK_UAI).count
    end

    it 'deletes a Matchable by hash' do
        delete "/api/matchables/#{MOCK_UAI}/#{MOCK_HASH}"

        expect( last_response.body ).to eq ''
        expect( Matchable[hash_item: MOCK_HASH] ).to be nil
    end
end
