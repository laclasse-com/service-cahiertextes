# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods

  before :all do
    TableCleaner.new( DB, [] ).clean

    CahierDeTextes.create(regroupement_id: 1,
                          date_creation: Time.now,
                          deleted: false)
    plage_horaire_debut = PlageHoraire.create(label: 'test_debut',
                                              debut: '08:30:00',
                                              fin: '09:00:00')
    plage_horaire_fin = PlageHoraire.create(label: 'test_fin',
                                            debut: '09:30:00',
                                            fin: '10:00:00')
    CreneauEmploiDuTemps.create(debut: plage_horaire_debut.id,
                                fin: plage_horaire_fin.id)
    TypeDevoir.create(label: 'RSpec',
                      description: 'Type de devoir tout spécial pour rspec')
  end

  def app
    CahierDeTextesAPI::API
  end

  # {{{ Cours
  ############ POST ############
  it 'renseigne une nouvelle séquence pédagogique' do
    cahier_de_textes_id = CahierDeTextes.all[ rand(0 .. CahierDeTextes.count - 1) ][:id]
    creneau_emploi_du_temps_id = CreneauEmploiDuTemps.all[ rand(0 .. CreneauEmploiDuTemps.count - 1) ][:id]
    date_cours = '2013-08-29'
    contenu = 'Exemple de séquence pédagogique.'
    ressources = [ { label: 'test1', url: 'https://localhost/docs/test1' },
                   { label: 'test2', url: 'https://localhost/docs/test2' } ]

    post( '/enseignant/cours',
          { cahier_de_textes_id: cahier_de_textes_id,
            creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
            date_cours: date_cours,
            contenu: contenu,
            ressources: ressources }.to_json,
          'CONTENT_TYPE' => 'application/json' )
    last_response.status.should == 201

    cours = Cours.last
    cours.cahier_de_textes_id.should == cahier_de_textes_id
    cours.creneau_emploi_du_temps_id.should == creneau_emploi_du_temps_id
    cours.date_cours.should == Date.parse('2013-08-29')
    cours.date_creation.should_not equal nil
    cours.date_modification.should equal nil
    cours.date_validation.should equal nil
    cours.contenu.should == contenu
    cours.deleted.should be_false
    cours.ressources.size.should == ressources.size
    cours.ressources.size.times { |i|
      cours.ressources[ i ].to_json['label'].should == ressources[ i ].to_json['label']
      cours.ressources[ i ].to_json['url'].should == ressources[ i ].to_json['url']
    }
  end

  ############ PUT ############
  it 'modifie une séquence pédagogique' do
    cours = Cours.last.clone
    contenu = 'Mise à jour de la séquence pédagogique.'
    ressources = [ { label: 'test1', url: 'https://localhost/docs/test1' },
                   { label: 'test2', url: 'https://localhost/docs/test2' } ]

    expected_ressources_size = cours.ressources.size + ressources.size

    put( "/enseignant/cours/#{cours.id}",
         { contenu: contenu,
           ressources: ressources }.to_json,
         'CONTENT_TYPE' => 'application/json' )
    last_response.status.should == 200

    new_cours = Cours[ cours.id ]

    new_cours.cahier_de_textes_id.should == cours.cahier_de_textes_id
    new_cours.creneau_emploi_du_temps_id.should == cours.creneau_emploi_du_temps_id
    new_cours.date_cours.should == cours.date_cours
    new_cours.date_creation.should == cours.date_creation
    new_cours.date_modification.should_not equal nil
    new_cours.date_modification.should be > cours.date_modification unless cours.date_modification.nil?
    new_cours.date_validation.should == cours.date_validation
    new_cours.contenu.should == contenu
    new_cours.deleted.should == cours.deleted
    new_cours.ressources.size.should == expected_ressources_size
  end

  ############ GET ############
  it 'récupère le détail d\'une séquence pédagogique' do
    cours = Cours.last

    get "/enseignant/cours/#{cours.id}"
    last_response.status.should == 200

    response_body = JSON.parse(last_response.body)

    response_body['cahier_de_textes_id'].should == cours.cahier_de_textes_id
    response_body['creneau_emploi_du_temps_id'].should == cours.creneau_emploi_du_temps_id
    response_body['date_cours'].should == cours.date_cours.to_s
    expect( Date.parse( response_body['date_creation'] ) ).to eq Date.parse( cours.date_creation.to_s ) unless cours.date_creation.nil?
    expect( Date.parse( response_body['date_modification'] ) ).to eq Date.parse( cours.date_modification.to_s ) unless cours.date_modification.nil?
    expect( Date.parse( response_body['date_validation'] ) ).to eq Date.parse( cours.date_validation.to_s ) unless cours.date_validation.nil?
    response_body['date_creation'].should_not equal nil
    response_body['contenu'].should == cours.contenu
    response_body['deleted'].should be_false
    response_body['ressources'].size.should == cours.ressources.size
  end

  ############ DELETE ############
  it 'efface une séquence pédagogique' do
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
  it 'crée un nouveau devoir' do
    cours_id = Cours.all[ rand(0 .. Cours.count - 1) ][:id]
    type_devoir_id = TypeDevoir.all[ rand(0 .. TypeDevoir.count - 1) ][:id]
    date_due = Time.now
    contenu = 'Exemple de devoir.'
    temps_estime = rand(0..120)
    ressources = [ { label: 'test1', url: 'https://localhost/docs/test1' },
                   { label: 'test2', url: 'https://localhost/docs/test2' } ]

    post( "/enseignant/devoir/#{cours_id}",
          { cours_id: cours_id,
            type_devoir_id: type_devoir_id,
            contenu: contenu,
            date_due: date_due,
            temps_estime: temps_estime,
            ressources: ressources }.to_json,
          'CONTENT_TYPE' => 'application/json' )
    last_response.status.should == 201

    devoir = Devoir.last

    devoir.cours_id.should == cours_id
    devoir.type_devoir_id.should == type_devoir_id
    expect( devoir.date_due ).to eq Date.parse( date_due.to_s )
    devoir.date_creation.should_not equal nil
    devoir.date_modification.should equal nil
    devoir.date_validation.should equal nil
    devoir.contenu.should == contenu
    devoir.temps_estime.should == temps_estime
    devoir.ressources.size.should equal ressources.size
  end

  ############ PUT ############
  it 'modifie un devoir' do
    devoir = Devoir.last
    type_devoir_id = TypeDevoir.all[ rand(0 .. TypeDevoir.count - 1) ][:id]
    date_due = Time.now
    contenu = 'Exemple de devoir totalement modifié.'
    temps_estime = rand(0..120)
    ressources = [ { label: 'test1', url: 'https://localhost/docs/test1' },
                   { label: 'test2', url: 'https://localhost/docs/test2' } ]

    expected_ressources_size = devoir.ressources.size + ressources.size

    put( "/enseignant/devoir/#{devoir.cours_id}",
         { cours_id: devoir.cours_id,
           type_devoir_id: type_devoir_id,
           contenu: contenu,
           date_due: date_due,
           temps_estime: temps_estime,
           ressources: ressources }.to_json,
         'CONTENT_TYPE' => 'application/json' )
    last_response.status.should == 200

    devoir2 = Devoir.last

    devoir2.cours_id.should == devoir.cours_id
    devoir2.type_devoir_id.should == devoir.type_devoir_id
    expect( devoir2.date_due ).to eq devoir.date_due
    expect( devoir2.date_creation ).to eq devoir.date_creation
    devoir2.date_modification.should_not equal nil
    expect( devoir2.date_validation ).to eq devoir.date_validation
    devoir2.contenu.should == contenu
    devoir2.temps_estime.should == temps_estime
    devoir2.ressources.size.should == expected_ressources_size
  end

  ############ GET ############
  it 'récupère les détails d\'un devoir' do
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
