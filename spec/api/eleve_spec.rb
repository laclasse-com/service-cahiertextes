# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods

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

    # Mock d'une session Élève
    module UserHelpers
      def user
        HashedUser.new( MOCKED_DATA[:users][:eleve][:rack_session] )
      end
    end
  end

  before :each do
    TableCleaner.new( DB, [] ).clean

    load_test_data
  end

  def app
    CahierDeTextesAPI::API
  end

  # {{{ Emploi du Temps
  ############ GET ############
  it 'récupère l\'emploi du temps de l\'élève' do
    debut = Date.today
    fin = debut + 7

    get "/v1/emplois_du_temps/du/#{debut}/au/#{fin}"

    pp last_response unless last_response.status == 200

    expect( last_response.status ).to eq 200
  end
  # }}}

  # {{{ Créneaux Emploi du Temps
  ############ GET ############
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
  # }}}

  # {{{ Cours
  ############ GET ############
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

  ############ POST ############
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

  ############ PUT ############
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
  # }}}

  # {{{ Devoir
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
  # }}}
end
