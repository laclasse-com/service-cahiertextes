# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods

  before :all do
    TableCleaner.new( DB, [] ).clean

    cahier_de_textes = CahierDeTextes.create(regroupement_id: 1,
                                             date_creation: Time.now,
                                             deleted: false)
    plage_horaire_debut = PlageHoraire.create(label: 'test_debut',
                                              debut: '08:30:00',
                                              fin: '09:00:00')
    plage_horaire_fin = PlageHoraire.create(label: 'test_fin',
                                            debut: '09:30:00',
                                            fin: '10:00:00')
    creneau_emploi_du_temps = CreneauEmploiDuTemps.create(debut: plage_horaire_debut.id,
                                                          fin: plage_horaire_fin.id)
    type_devoir = TypeDevoir.create(label: 'RSpec',
                                    description: 'Type de devoir tout spécial pour rspec')

    cours = Cours.create(cahier_de_textes_id: cahier_de_textes.id,
                         creneau_emploi_du_temps_id: creneau_emploi_du_temps.id,
                         date_cours: '2013-08-29',
                         contenu: 'Exemple de séquence pédagogique.' )
    Devoir.create(cours_id: cours.id,
                  type_devoir_id: type_devoir.id,
                  date_due: Time.now,
                  contenu: 'Exemple de devoir.',
                  temps_estime: rand(0..120) )
  end

  def app
    CahierDeTextesAPI::API
  end

  # {{{ Emploi du Temps
  ############ GET ############
  it 'récupère l\'emploi du temps de l\'élève' do

    get '/emploi_du_temps/'
    last_response.status.should == 200
  end
  # }}}

  # {{{ Cahier de Textes
  ############ GET ############
  it 'récupère le cahier de textes de l\'élève' do

    get '/cahier_de_textes/'
    last_response.status.should == 200
  end
  # }}}

  # {{{ Cours
  ############ GET ############
  it 'récupère le détail d\'une séquence pédagogique' do
    cours = Cours.last

    get "/cours/#{cours.id}"
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
    eleve_id = 1
    devoir = Devoir.all[ rand(0 .. Devoir.count - 1) ]

    get "/devoir/#{devoir.id}"
    last_response.status.should == 200

    response_body = JSON.parse( last_response.body )

    response_body['cours_id'].should == devoir.cours_id
    response_body['type_devoir_id'].should == devoir.type_devoir_id
    response_body['contenu'].should == devoir.contenu
    # response_body['fait'].should == devoir.fait_par?( eleve_id )
  end

  ############ PUT ############
  it 'note un devoir comme fait' do
    devoir = Devoir.all[ rand(0 .. Devoir.count - 1) ]

    put "/devoir/#{devoir.id}/fait", {}
    last_response.status.should == 200

    devoir.fait_par?( 1 ).should be_true
  end
  # }}}
end
