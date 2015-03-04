# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::V1::CreneauxEmploiDuTempsAPI do
  include Rack::Test::Methods

  before :each do
    TableCleaner.new( DB, [] ).clean

    load_test_data
  end

  def app
    CahierDeTextesAPI::API
  end

  before :all do
    module Laclasse
      module Helpers
        module Authentication
          def logged?
            LOGGER.info 'Yeah yeah you are logged *wink*'
            true
          end
        end
      end
    end
  end

  # Enseignant
  it 'récupère un créneau d\'emploi du temps' do
    id = CreneauEmploiDuTemps.all.sample.id

    LOGGER.debug "/v1/creneaux_emploi_du_temps/#{id}"

    get "/v1/creneaux_emploi_du_temps/#{id}"

    LOGGER.debug last_response if last_response.status == 500
    expect( last_response.status ).to eq 200

    response = JSON.parse last_response.body
    CreneauEmploiDuTemps[id].each do |key, value|
      expect( response[ key.to_s ] ).to eq value unless value.is_a? Time
      #expect( Time.parse( response[ key.to_s ] ) ).to eq Time.parse( value ) if value.is_a? Time
    end
  end

  it 'renseigne un nouveau créneau' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { uid: 'TestUser',
              user_detailed: { 'roles' => [ { 'etablissement_code_uai' => 'Test',
                                                              'role_id' => 'TECH' } ],
                                               'profil_actif' => { 'etablissement_code_uai' => 'Test',
                                                                   'profil_id' => 'ENS' } } }
          end
        end
      end
    end

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

    LOGGER.debug last_response if last_response.status == 500
    expect( last_response.status ).to eq 201

    response_body = JSON.parse(last_response.body)
    expect( CreneauEmploiDuTemps[response_body['id']].jour_de_la_semaine ).to eq jour - 1
    # expect( CreneauEmploiDuTemps[response_body['id']].heure_debut ).to eq heure_debut
    # expect( CreneauEmploiDuTemps[response_body['id']].heure_fin ).to eq heure_fin
    expect( CreneauEmploiDuTemps[response_body['id']].matiere_id ).to eq matiere_id
    # expect( CreneauEmploiDuTemps[response_body['id']].regroupement_id ).to eq regroupement_id
  end

  # Élève
  it 'fails to renseigne un nouveau créneau' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'Rien' } ],
                               'profil_actif' => { 'etablissement_code_uai' => 'Test',
                                                   'profil_id' => 'ELV' } } }
          end
        end
      end
    end

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

    LOGGER.debug last_response if last_response.status == 500
    expect( last_response.status ).to eq 401
  end
end
