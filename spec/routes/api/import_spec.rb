# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::ImportAPI' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    it 'records a new import' do
        nb_imports_before = Import.count

        post '/api/import/log/start/', structure_id: MOCK_UAI, type: "pronote", comment: "unit-test"

        body = JSON.parse( last_response.body )
        import = Import.last

        expect( body.length ).to eq Import.columns.count
        expect( Import.count ).to eq nb_imports_before + 1
        expect( import.structure_id ).to eq MOCK_UAI
        expect( import.type ).to eq "pronote"
        expect( import.comment ).to eq "unit-test"

        import.destroy
    end

    # it 'decrypts a Pronote file' do
    #     false
    # end
end
