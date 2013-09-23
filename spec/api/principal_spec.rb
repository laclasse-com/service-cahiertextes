# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods

  before :all do
    TableCleaner.new( DB, [] ).clean

    xml_filename = 'spec/fixtures/Edt_To_LaclasseCom_0134567A_Enclair.xml'
    post '/api/v0/pronote/xml', xml_file: Rack::Test::UploadedFile.new(xml_filename, 'text/xml')

    cahier_de_textes = CahierDeTextes.create(regroupement_id: 1,
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
    type_devoir = TypeDevoir.create(label: 'RSpec',
                                    description: 'Type de devoir tout spécial pour rspec')

    12.times {
      |month|
      rand(2..9).times {
        CreneauEmploiDuTempsEnseignant.select( :creneau_emploi_du_temps_id, :enseignant_id ).limit( 32 ).each { |item|
          cours = Cours.create(cahier_de_textes_id: cahier_de_textes.id,
                               creneau_emploi_du_temps_id: item.values[ :creneau_emploi_du_temps_id ],
                               date_cours: '2013-' + (month + 1).to_s + '-29',
                               contenu: 'Exemple de séquence pédagogique.',
                               enseignant_id: item.values[:enseignant_id] )
          Devoir.create(cours_id: cours.id,
                        type_devoir_id: type_devoir.id,
                        date_due: Time.now,
                        contenu: 'Exemple de devoir.',
                        temps_estime: rand(0..120) )
        }
      }
    }
  end

  def app
    CahierDeTextesAPI::API
  end

  # {{{ Cours
  it 'valide un cours' do
    cours_id = Cours.where( 'date_validation IS NULL' ).first.id

    put "/api/v0/cours/#{cours_id}/valide", {}
    last_response.status.should == 200

    Cours[ cours_id ].date_validation.nil?.should be_false
  end
  # }}}

  # {{{ Enseignants
  it 'récupère les statistiques par enseignants et par mois' do
    uai = '0134567A'

    get "/api/v0/etablissement/#{uai}/enseignant"
    last_response.status.should == 200

    response_body = JSON.parse( last_response.body )

    response_body.reduce( true ) {
      |are_we_good, enseignant|
      are_we_good && enseignant['statistiques'].size == 12
    }.should be_true
  end

  it 'récupère les statistiques par enseignants et par mois' do
    uai = '0134567A'
    enseignant_id = Cours.select(:enseignant_id).first[:enseignant_id].to_s

    get "/api/v0/etablissement/#{uai}/enseignant/#{enseignant_id}"
    last_response.status.should == 200

    response_body = JSON.parse( last_response.body )

    response_body['enseignant_id'].should == enseignant_id

    response_body['saisies'].count.should == 12
  end

  it 'valide tout le cahier de textes d\'un enseignant' do
    uai = '0134567A'
    enseignant_id = Cours.select(:enseignant_id).first[:enseignant_id].to_s

    put "/api/v0/etablissement/#{uai}/enseignant/#{enseignant_id}"
    last_response.status.should == 200

    Cours.where(enseignant_id: enseignant_id).where('date_validation IS NULL').count.should == 0
  end
  # }}}

  # {{{ Classes
  it 'récupère les statistiques par classes / mois / matières' do
    uai = '0134567A'

    get "/api/v0/etablissement/#{uai}/classe"
    last_response.status.should == 200

    response_body = JSON.parse( last_response.body )

    response_body.each {
      |classe|
      classe['par_mois'].size.should == 12
      classe['par_mois'].reduce( 0 ) {
        |total, mois|
        total + mois[ 'filled' ]
      }.should == classe[ 'filled' ]
      classe['par_mois'].reduce( 0 ) {
        |total, mois|
        total + mois[ 'validated' ]
      }.should == classe[ 'validated' ]
    }
  end

  it 'récupère les statistiques d\'une classe par mois / matières' do
    uai = '0134567A'
    classe_id = '1'

    get "/api/v0/etablissement/#{uai}/classe/#{classe_id}"
    last_response.status.should == 200

    response_body = JSON.parse( last_response.body )

    response_body['par_mois'].size.should == 12
    response_body['par_mois'].reduce( 0 ) {
      |total, mois|
      total + mois[ 'filled' ]
    }.should == response_body[ 'filled' ]
    response_body['par_mois'].reduce( 0 ) {
      |total, mois|
      total + mois[ 'validated' ]
    }.should == response_body[ 'validated' ]
  end

  it 'valide tout le cahier de textes d\'une classe' do
    uai = '0134567A'
    classe_id = '1'

    put "/api/v0/etablissement/#{uai}/classe/#{classe_id}"
    last_response.status.should == 200

    Cours.where(cahier_de_textes_id: CahierDeTextes.where(regroupement_id: classe_id).first.id ).where('date_validation IS NULL').count.should == 0
  end
  # }}}
end
