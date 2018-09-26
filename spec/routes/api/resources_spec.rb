# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::Resources' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    MOCK_LABEL = 'label'
    MOCK_NAME = 'name'

    lid = -1

    it 'creates multiple Resources' do
        post '/api/resources/', resources: [ { structure_id: MOCK_UAI, label: MOCK_LABEL, name: MOCK_NAME },
                                             { structure_id: "#{MOCK_UAI}2", label: "#{MOCK_LABEL}2", name: "#{MOCK_NAME}2" } ]

        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 2

        Resource.where(id: body.map { |l| l['id'] }).destroy
    end

    it 'creates a Resource' do
        post '/api/resources/', structure_id: MOCK_UAI, label: MOCK_LABEL, name: MOCK_NAME

        body = JSON.parse( last_response.body )
        lid = body['id']
        expect( body.length ).to eq Resource.columns.count
        expect( body['structure_id'] ).to eq MOCK_UAI
        expect( body['label'] ).to eq MOCK_LABEL
        expect( body['name'] ).to eq MOCK_NAME
    end

    it 'gets a Resource by id' do
        get "/api/resources/#{lid}"

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq lid
        expect( body.length ).to eq Resource.columns.count
        expect( body['structure_id'] ).to eq MOCK_UAI
        expect( body['label'] ).to eq MOCK_LABEL
        expect( body['name'] ).to eq MOCK_NAME
    end

    it 'gets Resources by structure_id' do
        get "/api/resources", structure_id: MOCK_UAI

        body = JSON.parse( last_response.body )
        cohort = Resource.where(structure_id: MOCK_UAI)
        expect( body.length ).to eq cohort.count
    end

    it 'gets Resources by label' do
        get "/api/resources", label: MOCK_UAI

        body = JSON.parse( last_response.body )
        cohort = Resource.where(label: MOCK_UAI)
        expect( body.length ).to eq cohort.count
    end

    it 'gets Resources by name' do
        get "/api/resources", name: MOCK_UAI

        body = JSON.parse( last_response.body )
        cohort = Resource.where(name: MOCK_UAI)
        expect( body.length ).to eq cohort.count
    end

    it 'modifies a Resource' do
        put "/api/resources/#{lid}", structure_id: "#{MOCK_UAI}#{MOCK_UAI}", label: "#{MOCK_LABEL}#{MOCK_LABEL}", name: "#{MOCK_NAME}#{MOCK_NAME}"

        body = JSON.parse( last_response.body )
        lid = body['id']
        expect( body.length ).to eq Resource.columns.count
        expect( body['id'] ).to eq lid
        expect( body['structure_id'] ).to eq "#{MOCK_UAI}#{MOCK_UAI}"
        expect( body['label'] ).to eq "#{MOCK_LABEL}#{MOCK_LABEL}"
        expect( body['name'] ).to eq "#{MOCK_NAME}#{MOCK_NAME}"
    end

    it 'deletes a Resource by id' do
        delete "/api/resources/#{lid}"

        expect( last_response.body ).to eq ''
        expect( Resource[id: lid] ).to be nil
    end
end
