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

  # {{{ Cours
  it 'valide un cours' do
    cours_id = Cours.where( 'date_validation IS NULL' ).first.id

    put "/v0/cours/#{cours_id}/valide", {}
    last_response.status.should == 200

    Cours[ cours_id ].date_validation.nil?.should be_false
  end
  # }}}

  # {{{ Enseignants
  it 'récupère les statistiques par enseignants et par mois' do
    uai = '0699999Z'

    get "/v0/etablissements/#{uai}/enseignants"
    last_response.status.should == 200

    response_body = JSON.parse( last_response.body )

    response_body.reduce( true ) {
      |are_we_good, enseignant|
      are_we_good && enseignant['classes'].reduce( true ) {
        |are_we_good_yet, regroupement|
        are_we_good_yet && regroupement['statistiques'].size == 12
      }
    }.should be_true
  end

  it 'récupère les statistiques d\'un enseignant par mois' do
    uai = '0699999Z'
    enseignant_id = Cours.select(:enseignant_id).first[:enseignant_id].to_s

    get "/v0/etablissements/#{uai}/enseignants/#{enseignant_id}"
    last_response.status.should == 200

    response_body = JSON.parse( last_response.body )

    response_body['enseignant_id'].should == enseignant_id
  end
  # }}}

  # {{{ Classes
  it 'récupère les statistiques des classes d\'un établissement' do
    uai = '0699999Z'

    get "/v0/etablissements/#{uai}/classes"
    last_response.status.should == 200

    response_body = JSON.parse( last_response.body )

    response_body.each {
      |regroupement|
      regroupement['matieres'].each {
        |matiere|
        matiere['mois'].size.should == 12
      }
    }
  end

  it 'récupère les statistiques d\'une classe' do
    uai = '0699999Z'
    classe_id = CreneauEmploiDuTempsRegroupement.select(:regroupement_id).map { |r| r.regroupement_id }.uniq.sample

    get "/v0/etablissements/#{uai}/classes/#{classe_id}"
    last_response.status.should == 200

    response_body = JSON.parse( last_response.body )

    response_body['matieres'].each {
      |matiere|
      matiere['mois'].size.should == 12
    }
  end

  it 'valide tout le cahier de textes d\'une classe' do
    uai = '0699999Z'
    classe_id = CreneauEmploiDuTempsRegroupement.select(:regroupement_id).map { |r| r.regroupement_id }.uniq.sample

    put "/v0/etablissements/#{uai}/classes/#{classe_id}"
    last_response.status.should == 200

    Cours.where(cahier_de_textes_id: CahierDeTextes.where(regroupement_id: classe_id).first.id ).where('date_validation IS NULL').count.should == 0
  end
  # }}}
end
