# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::ImportAPI' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    it 'FORBIDS recording a new import when not TECH' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        post '/api/import/log/start/', structure_id: MOCK_UAI, type: "pronote"

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'records a new import' do
        nb_imports_before = Import.count

        post '/api/import/log/start/', structure_id: MOCK_UAI, type: "pronote"

        body = JSON.parse( last_response.body )
        import = Import.last

        expect( body.length ).to eq Import.columns.count
        expect( Import.count ).to eq nb_imports_before + 1
        expect( import.structure_id ).to eq MOCK_UAI
        expect( import.import_type_id ).to eq ImportType[label: "pronote"]&.id
        expect( import.author_id ).to eq u_id

        import.destroy
    end

    it 'FORBIDS decryption of a Pronote file of another structure' do
        $mock_user = MOCK_USER_ADM  # rubocop:disable Style/GlobalVars

        post '/api/import/pronote/decrypt',
             file: Rack::Test::UploadedFile.new( 'spec/fixtures/Edt_To_LaclasseCom_0134567A.xml' )

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'decrypts a Pronote file' do
        if ENV['TRAVIS']
            puts 'Travis doesn\'t have the private key to test this'
        else
            $mock_user = MOCK_USER_ADM_PRONOTE  # rubocop:disable Style/GlobalVars

            post '/api/import/pronote/decrypt',
                 file: Rack::Test::UploadedFile.new( 'spec/fixtures/Edt_To_LaclasseCom_0134567A.xml' )

            body = JSON.parse( last_response.body )

            expect( body['structure_id'] ).to eq "0134567A"
            expect( body['subjects'] ).to_not be nil

            $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
        end
    end
end
