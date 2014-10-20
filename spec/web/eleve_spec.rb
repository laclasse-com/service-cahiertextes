# -*- coding: utf-8 -*-

require 'spec_helper'

feature CahierDeTextesAPI::Web do
  include Rack::Test::Methods

  before :each do
    # visit 'http://www.dev.laclasse.com/sso-mysql/login?service=http%3A%2F%2Flocalhost%3A9292%2Fct%2Fauth%2Fcas%2Fcallback%3Furl%3Dhttp%253A%252F%252Flocalhost%253A9292%252Fct%252F'
    visit 'http://localhost:9292/ct'

    fill_in 'Identifiant:', with: TEST_USER[ :username ]
    fill_in 'Mot de passe:', with: TEST_USER[ :password ]

    click_button 'SE CONNECTER'

    find_by_id( 'profils' ).select 'ERASME : Elève'
  end

  it 'checks that we\'re on the correct page' do
    expect( has_content? 'Liste des devoirs' ).to eq true
  end

  it 'goes to see the Liste des devoirs' do
    visit '/ct/#/eleve/devoirs'

    expect( has_no_checked_field? 'Afficher les devoirs déjà fait' ).to eq true
  end

  after :each do
    visit 'http://localhost:9292/ct'

    find( 'a > .glyphicon-log-out' ).click
  end
end
