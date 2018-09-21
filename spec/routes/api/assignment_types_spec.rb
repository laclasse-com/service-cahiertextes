# frozen_string_literal: true

require_relative '../../test_setup'

require_relative '../../../models/assignment'

describe 'CdTServer' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

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
end
