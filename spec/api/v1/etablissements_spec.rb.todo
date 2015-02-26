# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesAPI::V1::EtablissementsAPI do
  include Rack::Test::Methods

  before :all do
    module Annuaire
      module_function

      def get_user( _uid )
        MOCKED_DATA[:users][:principal][:annuaire]
      end

      def get_user_regroupements( uid )
        u = get_user( uid )
        { 'classes' => u['classes'],
          'groupes_eleves' => u['groupes_eleves'],
          'groupes_libres' => u['groupes_libres']
        }
      end

      # def get_etablissement_regroupements( _uai )
      #   MOCKED_DATA[:etablissement][:regroupements]
      # end

      def get_etablissement( _uai )
        MOCKED_DATA[:etablissement]
      end
    end

    # Mock d'une session Principal
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            HashedUser.new( MOCKED_DATA[:users][:principal][:rack_session] )
          end
        end
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

  # {{{ Enseignants
  it 'récupère les statistiques par enseignants et par mois' do
    uai = '0699999Z'

    get "/v1/etablissements/#{uai}/statistiques/enseignants"
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

    get "/v1/etablissements/#{uai}/statistiques/enseignants/#{enseignant_id}"
    expect( last_response.status ).to eq 200

    response_body = JSON.parse( last_response.body )

    expect( response_body['enseignant_id'] ).to eq enseignant_id
  end
  # }}}

  # {{{ Classes
  it 'récupère les statistiques des classes d\'un établissement' do
    uai = '0699999Z'

    get "/v1/etablissements/#{uai}/statistiques/classes"
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

    get "/v1/etablissements/#{uai}/statistiques/classes/#{classe_id}"
    expect( last_response.status ).to eq 200

    response_body = JSON.parse( last_response.body )

    response_body['matieres'].each {
      |matiere|
      expect( matiere['mois'].size ).to eq 12
    }
  end

  # }}}
end
