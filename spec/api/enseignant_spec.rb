# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods

  before :all do
    db_cleaner = TableCleaner.new DB, []
    db_cleaner.clean

    CahierDeTextes.create(regroupement_id: 1, date_creation: Time.now, deleted: false)
    plage_horaire_debut = PlageHoraire.create(label: 'test_debut', debut: '08:30:00', fin: '09:00:00')
    plage_horaire_fin = PlageHoraire.create(label: 'test_fin', debut: '09:30:00', fin: '10:00:00')
    CreneauEmploiDuTemps.create(debut: plage_horaire_debut.id, fin: plage_horaire_fin.id)
    TypeDevoir.create(label: 'RSpec', description: 'Type de devoir tout spécial pour rspec')
  end

  def app
    CahierDeTextesAPI::API
  end

  # {{{ Cours
  ############ POST ############
  it 'creates a new cours' do
    cahier_de_textes_id = CahierDeTextes.all[ rand(0 .. CahierDeTextes.count - 1) ][:id]
    creneau_emploi_du_temps_id = CreneauEmploiDuTemps.all[ rand(0 .. CreneauEmploiDuTemps.count - 1) ][:id]

    post( '/enseignant/cours',
          { cahier_de_textes_id: cahier_de_textes_id,
            creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
            date_cours: '2013-08-29',
            contenu: 'Exemple de séquence pédagogique.'}.to_json,
          'CONTENT_TYPE' => 'application/json' )
    last_response.status.should == 201

    cours = Cours.last
    cours.cahier_de_textes_id.should == cahier_de_textes_id
    cours.creneau_emploi_du_temps_id.should == creneau_emploi_du_temps_id
    cours.date_cours.should == Date.parse('2013-08-29')
    cours.date_creation.should_not equal nil
    cours.date_modification.should equal nil
    cours.date_validation.should equal nil
    cours.contenu.should == 'Exemple de séquence pédagogique.'
    cours.deleted.should be_false
  end

  ############ PUT ############
  it 'updates a cours' do
    cours = Cours.last

    put( "/enseignant/cours/#{cours.id}",
         { contenu: 'Mise à jour de la séquence pédagogique.'}.to_json,
         'CONTENT_TYPE' => 'application/json' )
    last_response.status.should == 200

    cours2 = Cours[ cours.id ]

    cours2.cahier_de_textes_id.should == cours.cahier_de_textes_id
    cours2.creneau_emploi_du_temps_id.should == cours.creneau_emploi_du_temps_id
    cours2.date_cours.should == cours.date_cours
    cours2.date_creation.should == cours.date_creation
    cours2.date_modification.should_not equal nil
    cours2.date_modification.should be > cours.date_modification unless cours.date_modification.nil?
    cours2.date_validation.should == cours.date_validation
    cours2.contenu.should == 'Mise à jour de la séquence pédagogique.'
    cours2.deleted.should == cours.deleted
  end

  ############ GET ############
  it 'gets the details of a cours' do
    cours = Cours.last

    get "/enseignant/cours/#{cours.id}"
    last_response.status.should == 200

    response_body = JSON.parse(last_response.body)

    response_body['cahier_de_textes_id'].should == cours.cahier_de_textes_id
    response_body['creneau_emploi_du_temps_id'].should == cours.creneau_emploi_du_temps_id
    response_body['date_cours'].should == cours.date_cours.to_s
    # response_body['date_creation'].should == cours.date_creation ? cours.date_creation.to_s : nil
    # response_body['date_modification'].should == cours.date_modification ? cours.date_modification.to_s : nil
    # response_body['date_validation'].should == cours.date_validation ? cours.date_validation.to_s : nil
    response_body['date_creation'].should_not equal nil
    response_body['contenu'].should == cours.contenu
    response_body['deleted'].should == cours.deleted
  end

  ############ DELETE ############
  it 'deletes a cours' do
    cours = Cours.last
    cours.deleted.should be_false

    delete "/enseignant/cours/#{cours.id}"

    cours2 = Cours[ cours.id ]
    cours2.deleted.should be_true

    get "/enseignant/cours/#{cours.id}"
    last_response.status.should == 404
  end
  # }}}

  # {{{ Devoir
  ############ POST ############
  it 'creates a new devoir' do
    cours_id = Cours.all[ rand(0 .. Cours.count - 1) ][:id]
    type_devoir_id = TypeDevoir.all[ rand(0 .. TypeDevoir.count - 1) ][:id]
    date_due = Time.now

    post( "/enseignant/devoir/#{cours_id}",
          { cours_id: cours_id,
            type_devoir_id: type_devoir_id,
            contenu: 'Exemple de devoir.',
            date_due: date_due }.to_json,
          'CONTENT_TYPE' => 'application/json' )
    last_response.status.should == 201

    devoir = Devoir.last
    devoir.cours_id.should == cours_id
    devoir.type_devoir_id.should == type_devoir_id
    expect(devoir.date_due).to eq Date.parse( date_due.to_s )
    devoir.date_creation.should_not equal nil
    devoir.date_modification.should equal nil
    devoir.date_validation.should equal nil
    devoir.contenu.should == 'Exemple de devoir.'
  end

  ############ PUT ############
  it 'updates a devoir' do
    devoir = Devoir.last
    type_devoir_id = TypeDevoir.all[ rand(0 .. TypeDevoir.count - 1) ][:id]
    date_due = Time.now

    put( "/enseignant/devoir/#{devoir.cours_id}",
         { cours_id: devoir.cours_id,
           type_devoir_id: type_devoir_id,
           contenu: 'Exemple de devoir totalement modifié.',
           date_due: date_due }.to_json,
         'CONTENT_TYPE' => 'application/json' )
    last_response.status.should == 200

    devoir2 = Devoir.last
    devoir2.cours_id.should == devoir.cours_id
    devoir2.type_devoir_id.should == devoir.type_devoir_id
    expect(devoir2.date_due).to eq Date.parse( devoir.date_due.to_s )
    expect(devoir2.date_creation).to eq devoir.date_creation
    devoir2.date_modification.should_not equal nil
    expect(devoir2.date_validation).to eq devoir.date_validation
    devoir2.contenu.should == 'Exemple de devoir totalement modifié.'
  end

  ############ GET ############
  it 'gets the details of a devoir' do
    devoir = Devoir.all[ rand(0 .. Devoir.count - 1) ]

    get "/enseignant/devoir/#{devoir.cours_id}"
    last_response.status.should == 200

    response_body = JSON.parse( last_response.body )

    response_body['cours_id'].should == devoir.cours_id
    response_body['type_devoir_id'].should == devoir.type_devoir_id
    response_body['contenu'].should be == devoir.contenu
  end
  # }}}
end
