# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::API do
  include Rack::Test::Methods

  before :each do
    TableCleaner.new( DB, [] ).clean

    load_test_data
  end

  def app
    CahierDeTextesAPI::API
  end

  # {{{ Cours
  it 'valide un cours' do
    cours_id = Cours.where( 'date_validation IS NULL' ).first.id

    put "/v1/cours/#{cours_id}/valide", {}
    expect( last_response.status ).to eq 200

    Cours[ cours_id ].date_validation.nil?.should eq false
  end
  # }}}

  # {{{ Enseignants
  it 'récupère les statistiques par enseignants et par mois' do
    uai = '0699999Z'

    get "/v1/etablissements/#{uai}/enseignants"
    expect( last_response.status ).to eq 200

    response_body = JSON.parse( last_response.body )

    expect( response_body.reduce( true ) {
              |are_we_good, enseignant|
              are_we_good && enseignant['classes'].reduce( true ) {
                |are_we_good_yet, regroupement|
                are_we_good_yet && regroupement['statistiques'].size == 12
              }
            } ).to eq true
  end

  it 'récupère les statistiques d\'un enseignant par mois' do
    uai = '0699999Z'
    enseignant_id = Cours.select(:enseignant_id).first[:enseignant_id].to_s

    get "/v1/etablissements/#{uai}/enseignants/#{enseignant_id}"
    expect( last_response.status ).to eq 200

    response_body = JSON.parse( last_response.body )

    expect( response_body['enseignant_id'] ).to eq enseignant_id
  end
  # }}}

  # {{{ Classes
  it 'récupère les statistiques des classes d\'un établissement' do
    uai = '0699999Z'

    get "/v1/etablissements/#{uai}/classes"
    expect( last_response.status ).to eq 200

    response_body = JSON.parse( last_response.body )

    response_body.each {
      |regroupement|
      regroupement['matieres'].each {
        |matiere|
        expect( matiere['mois'].size ).to eq 12
      }
    }
  end

  it 'récupère les statistiques d\'une classe' do
    uai = '0699999Z'
    classe_id = CreneauEmploiDuTempsRegroupement.select(:regroupement_id).map { |r| r.regroupement_id }.uniq.sample

    get "/v1/etablissements/#{uai}/classes/#{classe_id}"
    expect( last_response.status ).to eq 200

    response_body = JSON.parse( last_response.body )

    response_body['matieres'].each {
      |matiere|
      expect( matiere['mois'].size ).to eq 12
    }
  end

  # }}}
end
