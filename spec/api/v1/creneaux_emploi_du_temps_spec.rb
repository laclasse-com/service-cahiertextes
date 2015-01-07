# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::V1::CreneauxEmploiDuTempsAPI do
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
  ############ GET ############
  it 'récupère un créneau d\'emploi du temps' do
    id = CreneauEmploiDuTemps.all.sample.id
    get "/v1/creneaux_emploi_du_temps/#{id}"

    expect( last_response.status ).to eq 200

    response = JSON.parse last_response.body
    CreneauEmploiDuTemps[id].each do |key, value|
      expect( response[ key.to_s ] ).to eq value unless value.is_a? Time
      #expect( Time.parse( response[ key.to_s ] ) ).to eq Time.parse( value ) if value.is_a? Time
    end
  end

  it 'renseigne un nouveau créneau' do
    jour = rand 1..7
    heure_debut = Time.now.beginning_of_hour.iso8601
    heure_fin = (Time.now.beginning_of_hour + ( (rand 1..5) * 1800 )).iso8601
    matiere_id = CreneauEmploiDuTemps.all.sample.matiere_id
    regroupement_id = CreneauEmploiDuTempsRegroupement.all.sample.regroupement_id

    post '/v1/creneaux_emploi_du_temps/', { jour_de_la_semaine: jour,
                                            heure_debut: heure_debut,
                                            heure_fin: heure_fin,
                                            matiere_id: matiere_id,
                                            regroupement_id: regroupement_id }

    expect( last_response.status ).to eq 201

    response_body = JSON.parse(last_response.body)
    expect( CreneauEmploiDuTemps[response_body['id']].jour_de_la_semaine ).to eq jour - 1
    # expect( CreneauEmploiDuTemps[response_body['id']].heure_debut ).to eq heure_debut
    # expect( CreneauEmploiDuTemps[response_body['id']].heure_fin ).to eq heure_fin
    expect( CreneauEmploiDuTemps[response_body['id']].matiere_id ).to eq matiere_id
    # expect( CreneauEmploiDuTemps[response_body['id']].regroupement_id ).to eq regroupement_id
  end
end

describe CahierDeTextesAPI::V1::CreneauxEmploiDuTempsAPI do
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

  it 'fails to renseigne un nouveau créneau' do
    jour = rand 1..7
    heure_debut = Time.now.beginning_of_hour.iso8601
    heure_fin = (Time.now.beginning_of_hour + ( (rand 1..5) * 1800 )).iso8601
    matiere_id = CreneauEmploiDuTemps.all.sample.matiere_id
    regroupement_id = CreneauEmploiDuTempsRegroupement.all.sample.regroupement_id

    post '/v1/creneaux_emploi_du_temps/', { jour_de_la_semaine: jour,
                                            heure_debut: heure_debut,
                                            heure_fin: heure_fin,
                                            matiere_id: matiere_id,
                                            regroupement_id: regroupement_id }

    expect( last_response.status ).to eq 401
  end
end

describe CahierDeTextesAPI::V1::CreneauxEmploiDuTempsAPI do
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
end

describe CahierDeTextesAPI::V1::CreneauxEmploiDuTempsAPI do
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
end

describe CahierDeTextesAPI::V1::CreneauxEmploiDuTempsAPI do
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
end
