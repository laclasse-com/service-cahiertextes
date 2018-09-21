# frozen_string_literal: true

require_relative '../../test_setup'

require_relative '../../../models/location'

describe 'CdTServer' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    MOCK_LABEL = 'label'
    MOCK_NAME = 'name'

    lid = -1

    it 'creates multiple Locations' do
        post '/api/locations/', locations: [ { structure_id: MOCK_UAI, label: MOCK_LABEL, name: MOCK_NAME },
                                             { structure_id: "#{MOCK_UAI}2", label: "#{MOCK_LABEL}2", name: "#{MOCK_NAME}2" } ]

        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 2

        Location.where(id: body.map { |l| l['id'] }).destroy
    end

    it 'creates a Location' do
        post '/api/locations/', structure_id: MOCK_UAI, label: MOCK_LABEL, name: MOCK_NAME

        body = JSON.parse( last_response.body )
        lid = body['id']
        expect( body.length ).to eq Location.columns.count
        expect( body['structure_id'] ).to eq MOCK_UAI
        expect( body['label'] ).to eq MOCK_LABEL
        expect( body['name'] ).to eq MOCK_NAME
    end

    it 'gets a Location by id' do
        get "/api/locations/#{lid}"

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq lid
        expect( body.length ).to eq Location.columns.count
        expect( body['structure_id'] ).to eq MOCK_UAI
        expect( body['label'] ).to eq MOCK_LABEL
        expect( body['name'] ).to eq MOCK_NAME
    end

    it 'gets Locations by structure_id' do
        get "/api/locations", structure_id: MOCK_UAI

        body = JSON.parse( last_response.body )
        cohort = Location.where(structure_id: MOCK_UAI)
        expect( body.length ).to eq cohort.count
    end

    it 'gets Locations by label' do
        get "/api/locations", label: MOCK_UAI

        body = JSON.parse( last_response.body )
        cohort = Location.where(label: MOCK_UAI)
        expect( body.length ).to eq cohort.count
    end

    it 'gets Locations by name' do
        get "/api/locations", name: MOCK_UAI

        body = JSON.parse( last_response.body )
        cohort = Location.where(name: MOCK_UAI)
        expect( body.length ).to eq cohort.count
    end

    it 'modifies a Location' do
        put "/api/locations/#{lid}", structure_id: "#{MOCK_UAI}#{MOCK_UAI}", label: "#{MOCK_LABEL}#{MOCK_LABEL}", name: "#{MOCK_NAME}#{MOCK_NAME}"

        body = JSON.parse( last_response.body )
        lid = body['id']
        expect( body.length ).to eq Location.columns.count
        expect( body['id'] ).to eq lid
        expect( body['structure_id'] ).to eq "#{MOCK_UAI}#{MOCK_UAI}"
        expect( body['label'] ).to eq "#{MOCK_LABEL}#{MOCK_LABEL}"
        expect( body['name'] ).to eq "#{MOCK_NAME}#{MOCK_NAME}"
    end

    it 'deletes a Location by id' do
        delete "/api/locations/#{lid}"

        expect( last_response.body ).to eq ''
        expect( Location[id: lid] ).to be nil
    end
end
