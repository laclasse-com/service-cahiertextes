# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::Statistics' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    it 'IS NOT TESTED YET' do
        true
    end
end
