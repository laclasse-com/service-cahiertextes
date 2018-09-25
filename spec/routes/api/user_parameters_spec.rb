# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::UserParametersAPI' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    it 'gets user parameters' do
        up = UserParameters[uid: 'VZZ69999']
        up&.destroy

        get '/api/users/current/parametres'

        up = UserParameters[uid: LaClasse::Helpers::Auth.session['user'] ]
        expect( up ).to_not be nil

        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 3
        expect( body['uid'] ).to eq LaClasse::Helpers::Auth.session['user']

        parameters = JSON.parse( body['parameters'] )
        expect( parameters['affichage_types_de_devoir'] ).to be true
        expect( parameters['affichage_week_ends'] ).to be false

        up&.destroy
    end

    it 'sets user parameters' do
        up = UserParameters[uid: 'VZZ69999']
        up&.destroy

        put '/api/users/current/parametres', parameters: { 'affichage_types_de_devoir' => false,
                                                           'affichage_week_ends' => true }.to_json

        up = UserParameters[uid: LaClasse::Helpers::Auth.session['user'] ]
        expect( up ).to_not be nil

        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 3
        expect( body['uid'] ).to eq LaClasse::Helpers::Auth.session['user']

        parameters = JSON.parse( body['parameters'] )
        expect( parameters['affichage_types_de_devoir'] ).to be false
        expect( parameters['affichage_week_ends'] ).to be true

        up&.destroy
    end
end
