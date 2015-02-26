# -*- coding: utf-8 -*-

require 'spec_helper'

feature CahierDeTextesAPI::Web do
  include Rack::Test::Methods

  it 'logs in' do
    visit 'http://www.dev.laclasse.com/sso-mysql/login?service=http%3A%2F%2Flocalhost%3A9292%2Fct%2Fauth%2Fcas%2Fcallback%3Furl%3Dhttp%253A%252F%252Flocalhost%253A9292%252Fct%252F'

    fill_in 'Identifiant:', with: TEST_USER[ :username ]
    fill_in 'Mot de passe:', with: TEST_USER[ :password ]

    click_button 'SE CONNECTER'
  end

  it 'changes profile to DIR' do
    visit 'http://localhost:9292/ct'

    find_by_id( 'profils' ).select 'ERASME : Personel de direction de l\'etablissement'

    expect( page.has_content? 'Validation des saisies par enseignant' ).to eq true
  end

  it 'imports a pronote file' do
    visit 'http://localhost:9292/ct/#/principal/import'

    expect( page.has_button? 'Importer' ).to eq true

    attach_file 'fichier', 'spec/fixtures/Edt_To_LaclasseCom_0134567A.xml'

    click_button 'Importer'
  end

  it 'logs out' do
    visit 'http://localhost:9292/ct'

    find( 'a > .glyphicon-log-out' ).click
  end
end
