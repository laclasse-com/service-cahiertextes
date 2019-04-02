# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::Trails' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    it 'FORBIDS creation when not ENS DOC ADM or TECH' do
        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars
        post '/api/trails/', trails: [ { label: 'test', private: false } ]
        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'creates a trail' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        nb_trails_before = Trail.count
        label = "test #{Time.now}"

        post '/api/trails/', trails: [ { author_id: u_id, label: label, private: false },
                                       { author_id: u_id, label: "#{label}2", private: true } ]

        body = JSON.parse( last_response.body )

        expect( Trail.count ).to eq nb_trails_before + 2
        expect( body.first['label'] ).to eq label

        body.each do |t|
            Trail[id: t['id']]&.destroy
        end
    end

    it 'CANNOT create duplicate trails' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        label = "test #{Time.now}"
        post '/api/trails/', trails: [ { author_id: u_id, label: label, private: false },
                                       { author_id: u_id, label: label, private: true } ]
        expect( last_response.status ).to eq 403
    end

    it 'gets all trails' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        trail1 = Trail.create( label: "trail1",
                               private: true,
                               author_id: u_id )
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        get '/api/trails/'
        body = JSON.parse( last_response.body )

        expect( body.length ).to eq Trail.where( Sequel[{author_id: u_id }] | Sequel[{private: false}] ).count

        trail1&.destroy
    end

    it 'gets a specific trail by id' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        trail1 = Trail.create( label: "trail1",
                               private: true,
                               author_id: u_id )

        get "/api/trails/#{trail1.id}"
        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq trail1.label
        expect( body['private'] ).to eq trail1.private
        expect( body['author_id'] ).to eq trail1.author_id

        trail1&.destroy

        trail1 = Trail.create( label: "trail1",
                               private: false,
                               author_id: u_id )
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        get "/api/trails/#{trail1.id}"
        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq trail1.label
        expect( body['private'] ).to eq trail1.private
        expect( body['author_id'] ).to eq trail1.author_id

        trail1&.destroy
    end

    it 'CANNOT get another user\'s private trail by id' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        trail1 = Trail.create( label: "trail1",
                               private: true,
                               author_id: u_id )
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        get "/api/trails/#{trail1.id}"
        expect( last_response.status ).to eq 401

        trail1&.destroy
    end

    it 'FORBIDS update when not owner or TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars
        trail1 = Trail.create( label: "trail1",
                               private: true,
                               author_id: u_id )
        $mock_user = MOCK_USER_DIR  # rubocop:disable Style/GlobalVars

        put "/api/trails/#{trail1.id}", label: 'test2'

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'updates the label' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars
        trail1 = Trail.create( label: "trail1",
                               private: true,
                               author_id: u_id )

        put "/api/trails/#{trail1.id}", label: 'test2'
        body = JSON.parse( last_response.body )

        expect( body['label'] ).to eq 'test2'

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'FORBIDS deletion when not owner or TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars
        trail1 = Trail.create( label: "trail1",
                               private: true,
                               author_id: u_id )
        $mock_user = MOCK_USER_DIR  # rubocop:disable Style/GlobalVars

        delete "/api/trails/#{trail1.id}"

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'deletes a trail' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars
        trail1 = Trail.create( label: "trail1",
                               private: true,
                               author_id: u_id )

        delete "/api/trails/#{trail1.id}"

        expect( Trail[id: trail1.id] ).to be nil
        expect( last_response.body ).to eq ''
    end
end
