# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::Holidays' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    it 'gets holidays' do
        get '/api/holidays/'

        body = JSON.parse( last_response.body )

        expect( body ).to eq [1, 8, 9, 16, 17, 28, 29, 30, 31, 32, 33, 34, 35, 43, 44, 52]
    end
end
