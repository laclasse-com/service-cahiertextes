# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods

  before :all do
    module Annuaire
      module_function

      def get_user( _uid )
        MOCKED_DATA[:users][:principal][:annuaire]
      end

      def get_user_regroupements( uid )
        u = get_user( uid )
        { 'classes' => u['classes'],
          'groupes_eleves' => u['groupes_eleves'],
          'groupes_libres' => u['groupes_libres']
        }
      end

      def get_etablissement_regroupements( _uai )
        MOCKED_DATA[:etablissement][:regroupements]
      end
    end

    # Mock d'une session Élève
    module UserHelpers
      def user
        HashedUser.new( MOCKED_DATA[:users][:principal][:rack_session] )
      end
    end
  end

  before :each do
    TableCleaner.new( DB, [] ).clean
  end

  def app
    CahierDeTextesAPI::API
  end

  it 'links a failed identification to an Annuaire\'s ID' do
    sha256 = Digest::SHA256.hexdigest "test#{rand}"
    id_annuaire = 'test'
    FailedIdentification.create( sha256: sha256 )

    put "/v1/import/mrpni/#{sha256}/est/#{id_annuaire}",
        {}.to_json,
        'CONTENT_TYPE' => 'application/json'

    expect( last_response.status ).to eq 200

    body = JSON.parse( last_response.body )
    expect( body['sha256'] ).to eq sha256
    expect( body['id_annuaire'] ).to eq id_annuaire
  end
end
