# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods

  before :all do
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

    expect( last_response.status ).to eq 200
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
    eleve_id = 'VAC65103'
    devoir = Devoir.last

    put "/v1/devoirs/#{devoir.id}/fait"

    expect( last_response.status ).to eq 200

    expect( devoir.fait_par?( eleve_id ) ).to eq true
  end
  # }}}
end
