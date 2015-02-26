# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::V1::CoursAPI do
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
  ############ POST ############
  it 'renseigne une nouvelle séquence pédagogique' do
    regroupement_id = 1
    cahier_de_textes_id = CahierDeTextes.where( regroupement_id: regroupement_id ).first.id
    creneau_emploi_du_temps_id = CreneauEmploiDuTemps.all.sample.id
    date_cours = '2013-08-29'
    contenu = 'Exemple de séquence pédagogique.'
    ressources = [ { name: 'test1', hash: 'https://localhost/docs/test1' },
                   { name: 'test2', hash: 'https://localhost/docs/test2' } ]

    post( '/v1/cours',
          { regroupement_id: regroupement_id,
            creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
            date_cours: date_cours,
            contenu: contenu,
            ressources: ressources }.to_json,
          'CONTENT_TYPE' => 'application/json' )

    expect( last_response.status ).to eq 201

    cours = Cours.last
    expect( cours.cahier_de_textes_id ).to eq cahier_de_textes_id
    expect( cours.creneau_emploi_du_temps_id ).to eq creneau_emploi_du_temps_id
    expect( cours.date_cours ).to eq Date.parse('2013-08-29')
    expect( cours.date_creation ).to_not eq nil
    expect( cours.date_modification ).to eq nil
    expect( cours.date_validation ).to eq nil
    expect( cours.contenu ).to eq contenu
    expect( cours.deleted ).to eq false
    expect( cours.ressources.size ).to eq ressources.size
    cours.ressources.size.times { |i|
      expect( cours.ressources[ i ].to_json['label'] ).to eq ressources[ i ].to_json['label']
      expect( cours.ressources[ i ].to_json['url'] ).to eq ressources[ i ].to_json['url']
    }
  end

  ############ PUT ############
  it 'modifie une séquence pédagogique' do
    cours = Cours.last.clone
    contenu = 'Mise à jour de la séquence pédagogique.'
    ressources = [ { name: 'test1', hash: 'https://localhost/docs/test1' },
                   { name: 'test2', hash: 'https://localhost/docs/test2' } ]

    expected_ressources_size = ressources.size

    put( "/v1/cours/#{cours.id}",
         { contenu: contenu,
           ressources: ressources }.to_json,
         'CONTENT_TYPE' => 'application/json' )

    expect( last_response.status ).to eq 200

    new_cours = Cours[ cours.id ]

    expect( new_cours.cahier_de_textes_id ).to eq cours.cahier_de_textes_id
    expect( new_cours.creneau_emploi_du_temps_id ).to eq cours.creneau_emploi_du_temps_id
    expect( new_cours.date_cours ).to eq cours.date_cours
    expect( new_cours.date_creation ).to eq cours.date_creation
    expect( new_cours.date_modification ).to_not eq nil
    expect( new_cours.date_modification ).to eq > cours.date_modification unless cours.date_modification.nil?
    expect( new_cours.date_validation ).to eq cours.date_validation
    expect( new_cours.contenu ).to eq contenu
    expect( new_cours.deleted ).to eq cours.deleted
    expect( new_cours.ressources.size ).to eq expected_ressources_size
  end

  ############ GET ############
  it 'récupère le détail d\'une séquence pédagogique' do
    regroupement_id = 1
    creneau_emploi_du_temps_id = CreneauEmploiDuTemps.all.sample.id
    date_cours = '2013-08-29'
    contenu = 'Exemple de séquence pédagogique.'
    ressources = [ { name: 'test1', hash: 'https://localhost/docs/test1' },
                   { name: 'test2', hash: 'https://localhost/docs/test2' } ]

    post( '/v1/cours',
          { regroupement_id: regroupement_id,
            creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
            date_cours: date_cours,
            contenu: contenu,
            ressources: ressources }.to_json,
          'CONTENT_TYPE' => 'application/json' )

    expect( last_response.status ).to eq 201

    cours = Cours.last

    get "/v1/cours/#{cours.id}"
    expect( last_response.status ).to eq 200

    response_body = JSON.parse(last_response.body)

    expect( response_body['cahier_de_textes_id'] ).to eq cours.cahier_de_textes_id
    expect( response_body['creneau_emploi_du_temps_id'] ).to eq cours.creneau_emploi_du_temps_id
    expect( response_body['date_cours'] ).to eq cours.date_cours.to_s
    expect( Date.parse( response_body['date_creation'] ) ).to eq Date.parse( cours.date_creation.to_s ) unless cours.date_creation.nil?
    expect( Date.parse( response_body['date_modification'] ) ).to eq Date.parse( cours.date_modification.to_s ) unless cours.date_modification.nil?
    expect( Date.parse( response_body['date_validation'] ) ).to eq Date.parse( cours.date_validation.to_s ) unless cours.date_validation.nil?
    expect( response_body['date_creation'] ).to_not eq nil
    expect( response_body['contenu'] ).to eq cours.contenu
    expect( response_body['deleted'] ).to eq false
    expect( response_body['ressources'].size ).to eq cours.ressources.size
  end

  ############ DELETE ############
  it 'efface une séquence pédagogique' do
    regroupement_id = 1
    creneau_emploi_du_temps_id = CreneauEmploiDuTemps.all.sample.id
    date_cours = '2013-08-29'
    contenu = 'Exemple de séquence pédagogique.'
    ressources = [ { name: 'test1', hash: 'https://localhost/docs/test1' },
                   { name: 'test2', hash: 'https://localhost/docs/test2' } ]

    post( '/v1/cours',
          { regroupement_id: regroupement_id,
            creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
            date_cours: date_cours,
            contenu: contenu,
            ressources: ressources }.to_json,
          'CONTENT_TYPE' => 'application/json' )

    expect( last_response.status ).to eq 201

    cours = Cours.last
    expect( cours.deleted ).to eq false
    expect( cours.date_modification ).to eq nil

    delete "/v1/cours/#{cours.id}"

    cours2 = Cours[ cours.id ]
    expect( cours2.deleted ).to eq true
    expect( cours2.date_modification ).to_not eq nil
  end
end

describe CahierDeTextesAPI::V1::CoursAPI do
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
  it 'récupère le détail d\'une séquence pédagogique' do
    cours = Cours.last

    get "/v1/cours/#{cours.id}"
    expect( last_response.status ).to eq 200

    response_body = JSON.parse(last_response.body)

    expect( response_body['cahier_de_textes_id'] ).to eq cours.cahier_de_textes_id
    expect( response_body['creneau_emploi_du_temps_id'] ).to eq cours.creneau_emploi_du_temps_id
    expect( response_body['date_cours'] ).to eq cours.date_cours.to_s
    expect( Date.parse( response_body['date_creation'] ) ).to eq Date.parse( cours.date_creation.to_s ) unless cours.date_creation.nil?
    expect( Date.parse( response_body['date_modification'] ) ).to eq Date.parse( cours.date_modification.to_s ) unless cours.date_modification.nil?
    expect( Date.parse( response_body['date_validation'] ) ).to eq Date.parse( cours.date_validation.to_s ) unless cours.date_validation.nil?
    expect( response_body['contenu'] ).to eq cours.contenu
    expect( response_body['deleted'] ).to eq false
    expect( response_body['ressources'].size ).to eq cours.ressources.size
  end

  it 'fails to renseigne une nouvelle séquence pédagogique' do
    regroupement_id = 1
    creneau_emploi_du_temps_id = CreneauEmploiDuTemps.all.sample.id
    date_cours = '2013-08-29'
    contenu = 'Exemple de séquence pédagogique.'
    ressources = [ { name: 'test1', hash: 'https://localhost/docs/test1' },
                   { name: 'test2', hash: 'https://localhost/docs/test2' } ]

    post( '/v1/cours',
          { regroupement_id: regroupement_id,
            creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
            date_cours: date_cours,
            contenu: contenu,
            ressources: ressources }.to_json,
          'CONTENT_TYPE' => 'application/json' )

    expect( last_response.status ).to eq 401
  end

  it 'fails to modifie une séquence pédagogique' do
    cours = Cours.last.clone
    contenu = 'Mise à jour de la séquence pédagogique.'
    ressources = [ { name: 'test1', hash: 'https://localhost/docs/test1' },
                   { name: 'test2', hash: 'https://localhost/docs/test2' } ]

    put( "/v1/cours/#{cours.id}",
         { contenu: contenu,
           ressources: ressources }.to_json,
         'CONTENT_TYPE' => 'application/json' )

    expect( last_response.status ).to eq 401
  end
end

describe CahierDeTextesAPI::V1::CoursAPI do
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
  it 'valide un cours' do
    cours_id = Cours.where( 'date_validation IS NULL' ).first.id

    put "/v1/cours/#{cours_id}/valide", {}
    expect( last_response.status ).to eq 200

    expect( Cours[ cours_id ].date_validation ).to_not eq nil
  end

  # it 'fails to renseigne une nouvelle séquence pédagogique' do
  #   regroupement_id = 1
  #   creneau_emploi_du_temps_id = CreneauEmploiDuTemps.all.sample.id
  #   date_cours = '2013-08-29'
  #   contenu = 'Exemple de séquence pédagogique.'
  #   ressources = [ { name: 'test1', hash: 'https://localhost/docs/test1' },
  #                  { name: 'test2', hash: 'https://localhost/docs/test2' } ]

  #   post( '/v1/cours',
  #         { regroupement_id: regroupement_id,
  #           creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
  #           date_cours: date_cours,
  #           contenu: contenu,
  #           ressources: ressources }.to_json,
  #         'CONTENT_TYPE' => 'application/json' )

  #   p last_response
  #   expect( last_response.status ).to eq 401
  # end

  # it 'fails to modifie une séquence pédagogique' do
  #   cours = Cours.last.clone
  #   contenu = 'Mise à jour de la séquence pédagogique.'
  #   ressources = [ { name: 'test1', hash: 'https://localhost/docs/test1' },
  #                  { name: 'test2', hash: 'https://localhost/docs/test2' } ]

  #   put( "/v1/cours/#{cours.id}",
  #        { contenu: contenu,
  #          ressources: ressources }.to_json,
  #        'CONTENT_TYPE' => 'application/json' )

  #   p last_response
  #   expect( last_response.status ).to eq 401
  # end
end

describe CahierDeTextesAPI::V1::CoursAPI do
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
  it 'fails to renseigne une nouvelle séquence pédagogique' do
    regroupement_id = 1
    creneau_emploi_du_temps_id = CreneauEmploiDuTemps.all.sample.id
    date_cours = '2013-08-29'
    contenu = 'Exemple de séquence pédagogique.'
    ressources = [ { name: 'test1', hash: 'https://localhost/docs/test1' },
                   { name: 'test2', hash: 'https://localhost/docs/test2' } ]

    post( '/v1/cours',
          { regroupement_id: regroupement_id,
            creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
            date_cours: date_cours,
            contenu: contenu,
            ressources: ressources }.to_json,
          'CONTENT_TYPE' => 'application/json' )

    expect( last_response.status ).to eq 401
  end

  it 'fails to modifie une séquence pédagogique' do
    cours = Cours.last.clone
    contenu = 'Mise à jour de la séquence pédagogique.'
    ressources = [ { name: 'test1', hash: 'https://localhost/docs/test1' },
                   { name: 'test2', hash: 'https://localhost/docs/test2' } ]

    put( "/v1/cours/#{cours.id}",
         { contenu: contenu,
           ressources: ressources }.to_json,
         'CONTENT_TYPE' => 'application/json' )

    expect( last_response.status ).to eq 401
  end
end

describe CahierDeTextesAPI::V1::CoursAPI do
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
  it 'fails to renseigne une nouvelle séquence pédagogique' do
    regroupement_id = 1
    creneau_emploi_du_temps_id = CreneauEmploiDuTemps.all.sample.id
    date_cours = '2013-08-29'
    contenu = 'Exemple de séquence pédagogique.'
    ressources = [ { name: 'test1', hash: 'https://localhost/docs/test1' },
                   { name: 'test2', hash: 'https://localhost/docs/test2' } ]

    post( '/v1/cours',
          { regroupement_id: regroupement_id,
            creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
            date_cours: date_cours,
            contenu: contenu,
            ressources: ressources }.to_json,
          'CONTENT_TYPE' => 'application/json' )

    expect( last_response.status ).to eq 401
  end

  it 'fails to modifie une séquence pédagogique' do
    cours = Cours.last.clone
    contenu = 'Mise à jour de la séquence pédagogique.'
    ressources = [ { name: 'test1', hash: 'https://localhost/docs/test1' },
                   { name: 'test2', hash: 'https://localhost/docs/test2' } ]

    put( "/v1/cours/#{cours.id}",
         { contenu: contenu,
           ressources: ressources }.to_json,
         'CONTENT_TYPE' => 'application/json' )

    expect( last_response.status ).to eq 401
  end
end
