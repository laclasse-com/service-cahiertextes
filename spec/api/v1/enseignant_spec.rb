# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods

  before :all do
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

  before :each do
    TableCleaner.new( DB, [] ).clean

    load_test_data
  end

  def app
    CahierDeTextesAPI::API
  end

  # {{{ Emploi du Temps
  ############ GET ############
  it 'récupère l\'emploi du temps de l\'enseignant' do
    debut = Date.today
    fin = debut + 7

    get "/v1/emplois_du_temps/du/#{debut}/au/#{fin}"

    expect( last_response.status ).to eq 200
  end

  it 'récupère l\'emploi du temps de l\'enseignant' do
    debut = Date.today
    fin = debut + 7

    get '/v1/emplois_du_temps', { start: debut,
                                  end: fin }

    expect( last_response.status ).to eq 200
  end
  # }}}

  # {{{ Créneaux Emploi du Temps
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
  # }}}

  # {{{ Cours
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
  # }}}

  # {{{ Devoir
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
  # }}}
end
