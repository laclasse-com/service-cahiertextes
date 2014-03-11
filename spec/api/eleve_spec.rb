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

    get "/v0/emplois_du_temps/du/#{debut}/au/#{fin}"

    last_response.status.should == 200
  end
  # }}}

  # {{{ Cours
  ############ GET ############
  it 'récupère le détail d\'une séquence pédagogique' do
    cours = Cours.last

    get "/v0/cours/#{cours.id}"
    last_response.status.should == 200

    response_body = JSON.parse(last_response.body)

    response_body['cahier_de_textes_id'].should == cours.cahier_de_textes_id
    response_body['creneau_emploi_du_temps_id'].should == cours.creneau_emploi_du_temps_id
    response_body['date_cours'].should == cours.date_cours.to_s
    expect( Date.parse( response_body['date_creation'] ) ).to eq Date.parse( cours.date_creation.to_s ) unless cours.date_creation.nil?
    expect( Date.parse( response_body['date_modification'] ) ).to eq Date.parse( cours.date_modification.to_s ) unless cours.date_modification.nil?
    expect( Date.parse( response_body['date_validation'] ) ).to eq Date.parse( cours.date_validation.to_s ) unless cours.date_validation.nil?
    response_body['contenu'].should == cours.contenu
    response_body['deleted'].should be_false
    response_body['ressources'].size.should == cours.ressources.size
  end
  # }}}

  # {{{ Devoir
  ############ GET ############
  it 'récupère les détails d\'un devoir' do
    devoir = Devoir.all.sample

    get "/v0/devoirs/#{devoir.id}"
    last_response.status.should == 200

    response_body = JSON.parse( last_response.body )

    response_body['cours_id'].should == devoir.cours_id
    response_body['type_devoir_id'].should == devoir.type_devoir_id
    response_body['contenu'].should == devoir.contenu
  end

  ############ PUT ############
  it 'note un devoir comme fait' do
    eleve_id = 'VAA61181'
    devoir = Devoir.all.sample

    put "/v0/devoirs/#{devoir.id}/fait"
    last_response.status.should == 200

    devoir.fait_par?( eleve_id ).should be_true
  end
  # }}}
end
