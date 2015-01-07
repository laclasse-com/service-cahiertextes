# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::V1::EmploisDuTempsAPI do
  include Rack::Test::Methods

  before :each do
    TableCleaner.new( DB, [] ).clean

    load_test_data
  end

  def app
    CahierDeTextesAPI::API
  end

  # Enseignant
  before :all do
    class HashedUser
      def admin?
        false
      end
    end

    module Annuaire
      module_function

      def get_user( _uid )
        MOCKED_DATA[:users][:enseignant][:annuaire]
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

    # Mock d'une session Enseignant
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            HashedUser.new( MOCKED_DATA[:users][:enseignant][:rack_session] )
          end
        end
      end
    end
  end
  it 'récupère l\'emploi du temps de l\'enseignant' do
    debut = Date.today
    fin = debut + 7

    get "/v1/emplois_du_temps/du/#{debut}/au/#{fin}"

    expect( last_response.status ).to eq 200

    get '/v1/emplois_du_temps', { start: debut,
                                  end: fin }

    expect( last_response.status ).to eq 200
  end
end

describe CahierDeTextesAPI::V1::EmploisDuTempsAPI do
  include Rack::Test::Methods

  before :each do
    TableCleaner.new( DB, [] ).clean

    load_test_data
  end

  def app
    CahierDeTextesAPI::API
  end

  # Élève
  before :all do
    class HashedUser
      def admin?
        false
      end
    end

    module Annuaire
      module_function

      def get_user( _uid )
        MOCKED_DATA[:users][:eleve][:annuaire]
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

    # Mock d'une session Eleve
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            HashedUser.new( MOCKED_DATA[:users][:eleve][:rack_session] )
          end
        end
      end
    end
  end
  it 'récupère l\'emploi du temps de l\'eleve' do
    debut = Date.today
    fin = debut + 7

    get "/v1/emplois_du_temps/du/#{debut}/au/#{fin}"

    expect( last_response.status ).to eq 200

    get '/v1/emplois_du_temps', { start: debut,
                                  end: fin }

    expect( last_response.status ).to eq 200
  end
end

describe CahierDeTextesAPI::V1::EmploisDuTempsAPI do
  include Rack::Test::Methods

  before :each do
    TableCleaner.new( DB, [] ).clean

    load_test_data
  end

  def app
    CahierDeTextesAPI::API
  end

  # Principal
  before :all do
    class HashedUser
      def admin?
        false
      end
    end

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

    # Mock d'une session Principal
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            HashedUser.new( MOCKED_DATA[:users][:principal][:rack_session] )
          end
        end
      end
    end
  end
  it 'récupère l\'emploi du temps du principal' do
    debut = Date.today
    fin = debut + 7

    get "/v1/emplois_du_temps/du/#{debut}/au/#{fin}"

    expect( last_response.status ).to eq 200

    get '/v1/emplois_du_temps', { start: debut,
                                  end: fin }

    expect( last_response.status ).to eq 200
  end
end

describe CahierDeTextesAPI::V1::EmploisDuTempsAPI do
  include Rack::Test::Methods

  before :each do
    TableCleaner.new( DB, [] ).clean

    load_test_data
  end

  def app
    CahierDeTextesAPI::API
  end

  # Vie Scolaire
  before :all do
    class HashedUser
      def admin?
        false
      end
    end

    module Annuaire
      module_function

      def get_user( _uid )
        MOCKED_DATA[:users][:vie_scolaire][:annuaire]
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

    # Mock d'une session Vie_Scolaire
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            HashedUser.new( MOCKED_DATA[:users][:vie_scolaire][:rack_session] )
          end
        end
      end
    end
  end
  it 'récupère l\'emploi du temps du CPE' do
    debut = Date.today
    fin = debut + 7

    get "/v1/emplois_du_temps/du/#{debut}/au/#{fin}"

    expect( last_response.status ).to eq 200

    get '/v1/emplois_du_temps', { start: debut,
                                  end: fin }

    expect( last_response.status ).to eq 200
  end
end

describe CahierDeTextesAPI::V1::EmploisDuTempsAPI do
  include Rack::Test::Methods

  before :each do
    TableCleaner.new( DB, [] ).clean

    load_test_data
  end

  def app
    CahierDeTextesAPI::API
  end

  # Parent
  before :all do
    class HashedUser
      def admin?
        false
      end
    end

    module Annuaire
      module_function

      def get_user( _uid )
        MOCKED_DATA[:users][:parent][:annuaire]
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

    # Mock d'une session Parent
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            HashedUser.new( MOCKED_DATA[:users][:parent][:rack_session] )
          end
        end
      end
    end
  end
  it 'récupère l\'emploi du temps du parent' do
    debut = Date.today
    fin = debut + 7

    get "/v1/emplois_du_temps/du/#{debut}/au/#{fin}", { uai: '0699999Z',
                                                        uid: 'VAA00000' }

    expect( last_response.status ).to eq 200

    get '/v1/emplois_du_temps', { start: debut,
                                  end: fin,
                                  uai: '0699999Z',
                                  uid: 'VAA00000' }

    expect( last_response.status ).to eq 200
  end
end
