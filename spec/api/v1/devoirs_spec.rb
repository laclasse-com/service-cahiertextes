# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::V1::DevoirsAPI do
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
    module UserHelpers
      def user
        HashedUser.new( MOCKED_DATA[:users][:enseignant][:rack_session] )
      end
    end
  end

  ############ POST ############
  it 'crée un nouveau devoir' do
    cours_id = Cours.all.sample.id
    type_devoir_id = TypeDevoir.all.sample.id
    date_due = Time.now
    contenu = 'Exemple de devoir.'
    temps_estime = rand(0..120)
    ressources = [ { name: 'test1', hash: 'https://localhost/docs/test1' },
                   { name: 'test2', hash: 'https://localhost/docs/test2' } ]
    creneau_emploi_du_temps_id = CreneauEmploiDuTemps.last.id

    post( '/v1/devoirs/', { cours_id: cours_id,
                            type_devoir_id: type_devoir_id,
                            contenu: contenu,
                            creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
                            date_due: date_due,
                            temps_estime: temps_estime,
                            ressources: ressources }.to_json,
          'CONTENT_TYPE' => 'application/json' )

    expect( last_response.status ).to eq 201

    devoir = Devoir.last

    expect( devoir.cours_id ).to eq cours_id
    expect( devoir.type_devoir_id ).to eq type_devoir_id
    expect( devoir.date_due ).to eq Date.parse( date_due.to_s )
    expect( devoir.date_creation ).to_not eq nil
    expect( devoir.date_modification ).to eq nil
    expect( devoir.date_validation ).to eq nil
    expect( devoir.contenu ).to eq contenu
    expect( devoir.temps_estime ).to eq temps_estime
    expect( devoir.ressources.size ).to eq ressources.size
  end

  ############ PUT ############
  it 'modifie un devoir' do
    devoir = Devoir.last

    type_devoir_id = TypeDevoir.all.sample.id
    date_due = Time.now
    creneau_emploi_du_temps_id = CreneauEmploiDuTemps.last.id
    contenu = 'Exemple de devoir totalement modifié.'
    temps_estime = rand(0..120)
    ressources = [ { name: 'test1', hash: 'https://localhost/docs/test1' },
                   { name: 'test2', hash: 'https://localhost/docs/test2' } ]

    expected_ressources_size = ressources.size

    put( "/v1/devoirs/#{devoir.id}",
         { cours_id: devoir.cours_id,
           type_devoir_id: type_devoir_id,
           contenu: contenu,
           creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
           date_due: date_due,
           temps_estime: temps_estime,
           ressources: ressources }.to_json,
         'CONTENT_TYPE' => 'application/json' )
    expect( last_response.status ).to eq 200

    devoir2 = Devoir[ devoir.id ]

    expect( devoir2.cours_id ).to eq devoir.cours_id
    expect( devoir2.type_devoir_id ).to eq type_devoir_id
    expect( Date.parse( devoir2.date_due.to_s ) ).to eq Date.parse( date_due.to_s )
    expect( devoir2.date_creation ).to eq devoir.date_creation
    expect( devoir2.date_modification ).to_not eq nil
    expect( devoir2.date_validation ).to eq devoir.date_validation
    expect( devoir2.contenu ).to eq contenu
    expect( devoir2.temps_estime ).to eq temps_estime
    expect( devoir2.ressources.size ).to eq expected_ressources_size
  end

  ############ GET ############
  it 'récupère les détails d\'un devoir' do
    devoir = Devoir.all.sample

    get "/v1/devoirs/#{devoir.id}"
    expect( last_response.status ).to eq 200

    response_body = JSON.parse( last_response.body )

    expect( response_body['cours_id'] ).to eq devoir.cours_id
    expect( response_body['type_devoir_id'] ).to eq devoir.type_devoir_id
    expect( response_body['contenu'] ).to eq devoir.contenu
  end
end

describe CahierDeTextesAPI::V1::DevoirsAPI do
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
    module UserHelpers
      def user
        HashedUser.new( MOCKED_DATA[:users][:eleve][:rack_session] )
      end
    end
  end
  ############ GET ############
  it 'récupère les détails d\'un devoir' do
    devoir = Devoir.all.sample

    get "/v1/devoirs/#{devoir.id}"
    expect( last_response.status ).to eq 200

    response_body = JSON.parse( last_response.body )

    expect( response_body['cours_id'] ).to eq devoir.cours_id
    expect( response_body['type_devoir_id'] ).to eq devoir.type_devoir_id
    expect( response_body['contenu'] ).to eq devoir.contenu
  end

  ############ PUT ############
  it 'note un devoir comme fait' do
    eleve_id = MOCKED_DATA[:users][:eleve][:annuaire]['id_ent']
    devoir = Devoir.last

    put "/v1/devoirs/#{devoir.id}/fait"

    expect( last_response.status ).to eq 200

    expect( devoir.fait_par?( eleve_id ) ).to eq true
  end
end

describe CahierDeTextesAPI::V1::DevoirsAPI do
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
    module UserHelpers
      def user
        HashedUser.new( MOCKED_DATA[:users][:principal][:rack_session] )
      end
    end
  end
end

describe CahierDeTextesAPI::V1::DevoirsAPI do
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
    module UserHelpers
      def user
        HashedUser.new( MOCKED_DATA[:users][:vie_scolaire][:rack_session] )
      end
    end
  end
end

describe CahierDeTextesAPI::V1::DevoirsAPI do
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
    module UserHelpers
      def user
        HashedUser.new( MOCKED_DATA[:users][:parent][:rack_session] )
      end
    end
  end
end
