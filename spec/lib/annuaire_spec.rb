# -*- coding: utf-8 -*-
# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

require_relative '../../lib/annuaire'
require 'rest-client'

describe Annuaire do
  before(:each) do
    @uri = 'http://localhost'
    @srv = 'users/VAA60001'
    @args = { expand: 'true' }
    @url_annuaire_v2 = 'http://www.dev.laclasse.com/pls/public/!ajax_server.service?p_rendertype=none&serviceName=ServiceApi'
    @url_annuaire_v3 = 'http://www.dev.laclasse.com/api/app'
  end

  it 'should build a canonical string mode api V3' do
    ANNUAIRE[:api_mode] = 'v3'
    a = { p2: 'v2', p1: 'v1' }
    expect( Annuaire.build_canonical_string(a) ).to eq '?p1=v1&p2=v2;'
  end

  it 'should build an empty canonical string mode api V3' do
    ANNUAIRE[:api_mode] = 'v3'
    a = {}
    expect( Annuaire.build_canonical_string(a) ).to eq '?;'
  end

  it 'should build a canonical string mode api V2' do
    ANNUAIRE[:api_mode] = 'v2'
    a = { p2: 'v2', p1: 'v1' }
    expect( Annuaire.build_canonical_string(a) ).to eq '&p1=v1&p2=v2;'
  end

  it 'should build an empty canonical string mode api V2' do
    ANNUAIRE[:api_mode] = 'v2'
    a = {}
    expect( Annuaire.build_canonical_string(a) ).to eq '&;'
  end

  it 'should sign the request in api V3 mode' do
    ANNUAIRE[:api_mode] = 'v3'
    signed_url = Annuaire.sign( @uri, @srv, @args )

    ts = CGI.unescape(signed_url.slice(/timestamp\=.*\;/)).sub('timestamp=', '').sub(';', '')

    canonical_string = "#{@uri}/#{@srv}"
    canonical_string += Annuaire.build_canonical_string( @args )

    canonical_string_to_sign = "#{canonical_string}#{ts};#{ANNUAIRE[:app_id]}"

    signature = Annuaire.build_signature( canonical_string_to_sign, ts )
    expect( signed_url ).to eq "#{canonical_string}#{signature}"
  end

  it 'should sign the request in api V2 mode' do
    ANNUAIRE[:api_mode] = 'v2'
    @uri = 'http://www.dev.laclasse.com/pls/public/!ajax_server.service=ServiceApiUser&p_rendertype=none&uid='
    signed_url = Annuaire.sign(@uri, @srv, @args)
    ts = CGI.unescape(signed_url.slice(/timestamp\=.*\;/)).sub('timestamp=', '').sub(';', '')
    canonical_string = Annuaire.build_canonical_string(@args)
    signature = Annuaire.build_signature(canonical_string, ts)
    expect( signed_url ).to eq "#{@uri}#{@srv}#{canonical_string}#{signature}"
  end

  it 'should sign the request in api V3 mode without args' do
    ANNUAIRE[:api_mode] = 'v3'
    @args = {}
    signed_url = Annuaire.sign( @uri, @srv, @args )

    ts = CGI.unescape(signed_url.slice(/timestamp\=.*\;/)).sub('timestamp=', '').sub(';', '')

    canonical_string = "#{@uri}/#{@srv}"
    canonical_string += Annuaire.build_canonical_string( @args )

    canonical_string_to_sign = "#{canonical_string}#{ts};#{ANNUAIRE[:app_id]}"

    signature = Annuaire.build_signature( canonical_string_to_sign, ts )
    expect( signed_url ).to eq "#{canonical_string}#{signature}"
  end

  it 'should sign the request in api V2 mode without args' do
    ANNUAIRE[:api_mode] = 'v2'
    @args = {}
    @uri = 'http://www.dev.laclasse.com/pls/public/!ajax_server.service=ServiceApiUser&p_rendertype=none&uid='
    signed_url = Annuaire.sign(@uri, @srv, @args)
    ts = CGI.unescape(signed_url.slice(/timestamp\=.*\;/)).sub('timestamp=', '').sub(';', '')
    canonical_string = Annuaire.build_canonical_string(@args)
    signature = Annuaire.build_signature(canonical_string, ts)
    expect( signed_url ).to eq "#{@uri}#{@srv}#{canonical_string}#{signature}"
  end

  it ': function compat_service should return users/VAA60001 for users/VAA60001 service (mode V3)' do
    ANNUAIRE[:api_mode] = 'v3'
    expect( Annuaire.compat_service(@srv) ).to eq @srv
  end

  it ': function compat_service should return Users&uid=VAA60001 for users/VAA60001 service (mode V2)' do
    ANNUAIRE[:api_mode] = 'v2'
    expect( Annuaire.compat_service(@srv) ).to eq 'Users&uid=VAA60001'
  end

  it ': function compat_service should return etablissements/0699999Z for etablissements/0699999Z service (mode V3)' do
    ANNUAIRE[:api_mode] = 'v3'
    expect( Annuaire.compat_service('etablissements/0699999Z') ).to eq 'etablissements/0699999Z'
  end

  it ': function compat_service should return Etablissements&uai=0699999Z for etablissements/0699999Z service (mode V2)' do
    ANNUAIRE[:api_mode] = 'v2'
    expect( Annuaire.compat_service('etablissements/0699999Z') ).to eq 'Etablissements&uai=0699999Z'
  end

  it ': function compat_service should return matieres/1234 for matieres/1234 service (mode V3)' do
    ANNUAIRE[:api_mode] = 'v3'
    expect( Annuaire.compat_service('matieres/1234') ).to eq 'matieres/1234'
  end

  it ': function compat_service should return Matieres&code=1234 for matieres/1234 service (mode V2)' do
    ANNUAIRE[:api_mode] = 'v2'
    expect( Annuaire.compat_service('matieres/1234') ).to eq 'Matieres&code=1234'
  end

  it ': function compat_service should return matieres/libelle/MATH for matieres/libelle/MATH (mode V3)' do
    ANNUAIRE[:api_mode] = 'v3'
    expect( Annuaire.compat_service('matieres/libelle/MATH') ).to eq 'matieres/libelle/MATH'
  end

  it ': function compat_service should return Matieres&lib=MATH for matieres/libelle/MATH (mode V2)' do
    ANNUAIRE[:api_mode] = 'v2'
    Annuaire.set_search true
    expect( Annuaire.compat_service('matieres/libelle/MATH') ).to eq 'Matieres&lib=MATH'
  end

  it ': function compat_service should return regroupements/123 for regroupements/123 service (mode V3)' do
    ANNUAIRE[:api_mode] = 'v3'
    expect( Annuaire.compat_service('regroupements/123') ).to eq 'regroupements/123'
  end

  it ': function compat_service should return Regroupements&grp_id=123 for regroupements/123 service (mode V2)' do
    ANNUAIRE[:api_mode] = 'v2'
    Annuaire.set_search false
    expect( Annuaire.compat_service('regroupements') ).to eq 'Regroupements&grp_id='
  end

  it ': function compat_service should return regroupement/groupe1 for regroupement/groupe1 service (mode V3)' do
    ANNUAIRE[:api_mode] = 'v3'
    expect( Annuaire.compat_service('regroupement/groupe1') ).to eq 'regroupement/groupe1'
  end

  it ': function compat_service should return regroupement&etablissement=0699990Z&nom=groupe1 for regroupement/groupe1 service (mode V2)' do
    ANNUAIRE[:api_mode] = 'v2'
    Annuaire.set_search true
    expect( Annuaire.compat_service('regroupement') ).to eq 'regroupement'
  end

  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour get_user" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r2 = Annuaire.get_user 'VPG60307'
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.get_user 'VAA61315'

    expect( r2.key?('id') ).to eq r3.key?('id')
    expect( r2.key?('id_sconet') ).to eq r3.key?('id_sconet')
    expect( r2.key?('id_jointure_aaf') ).to eq r3.key?('id_jointure_aaf')
    expect( r2.key?('login') ).to eq r3.key?('login')
    expect( r2.key?('nom') ).to eq r3.key?('nom')
    expect( r2.key?('prenom') ).to eq r3.key?('prenom')
    expect( r2.key?('sexe') ).to eq r3.key?('sexe')
    expect( r2.key?('id_ent') ).to eq r3.key?('id_ent')
    expect( r2.key?('date_naissance') ).to eq r3.key?('date_naissance')
    expect( r2.key?('adresse') ).to eq r3.key?('adresse')
    expect( r2.key?('code_postal') ).to eq r3.key?('code_postal')
    expect( r2.key?('ville') ).to eq r3.key?('ville')
    expect( r2.key?('avatar') ).to eq r3.key?('avatar')
    expect( r2.key?('full_name') ).to eq r3.key?('full_name')
    expect( r2.key?('profils') ).to eq r3.key?('profils')
    expect( r2.key?('telephones') ).to eq r3.key?('telephones')
    expect( r2.key?('emails') ).to eq r3.key?('emails')

    # r3.each { |k, v| puts "r2.key?('"+k.to_s+"').should be r3.key?('"+k.to_s+"')" }
  end

  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour get_etablissement" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r2 = Annuaire.get_etablissement '0699990Z'
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.get_etablissement '0699999Z'
    expect( r2.key?('id') ).to eq r3.key?('id')
    expect( r2.key?('code_uai') ).to eq r3.key?('code_uai')
    expect( r2.key?('nom') ).to eq r3.key?('nom')
    expect( r2.key?('adresse') ).to eq r3.key?('adresse')
    expect( r2.key?('code_postal') ).to eq r3.key?('code_postal')
    expect( r2.key?('ville') ).to eq r3.key?('ville')
    expect( r2.key?('type_etablissement_id') ).to eq r3.key?('type_etablissement_id')
    expect( r2.key?('telephone') ).to eq r3.key?('telephone')
    expect( r2.key?('fax') ).to eq r3.key?('fax')
    expect( r2.key?('full_name') ).to eq r3.key?('full_name')
    expect( r2.key?('alimentation_state') ).to eq r3.key?('alimentation_state')
    expect( r2.key?('alimentation_date') ).to eq r3.key?('alimentation_date')
    expect( r2.key?('data_received') ).to eq r3.key?('data_received')
    expect( r2.key?('longitude') ).to eq r3.key?('longitude')
    expect( r2.key?('latitude') ).to eq r3.key?('latitude')
    expect( r2.key?('site_url') ).to eq r3.key?('site_url')
    expect( r2.key?('logo') ).to eq r3.key?('logo')
    expect( r2.key?('classes') ).to eq r3.key?('classes')
    expect( r2.key?('groupes_eleves') ).to eq r3.key?('groupes_eleves')
    expect( r2.key?('groupes_libres') ).to eq r3.key?('groupes_libres')
    expect( r2.key?('personnel') ).to eq r3.key?('personnel')
    expect( r2.key?('contacts') ).to eq r3.key?('contacts')
    expect( r2.key?('eleves') ).to eq r3.key?('eleves')
    expect( r2.key?('enseignants') ).to eq r3.key?('enseignants')
    expect( r2.key?('parents') ).to eq r3.key?('parents')
  end

  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour get_matiere" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r2 =  Annuaire.get_matiere '001600'
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.get_matiere '001600'
    expect( r2.key?('json_class') ).to eq r3.key?('json_class')
    expect( r2.key?('id') ).to eq r3.key?('id')
    expect( r2.key?('libelle_court') ).to eq r3.key?('libelle_court')
    expect( r2.key?('libelle_long') ).to eq r3.key?('libelle_long')
  end

  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour get_regroupement" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r2 =  Annuaire.get_regroupement '1363'
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.get_regroupement '1363'
    expect( r2.key?('id') ).to eq r3.key?('id')
    expect( r2.key?('etablissement_id') ).to eq r3.key?('etablissement_id')
    expect( r2.key?('libelle') ).to eq r3.key?('libelle')
    expect( r2.key?('libelle_aaf') ).to eq r3.key?('libelle_aaf')
    expect( r2.key?('type_regroupement_id') ).to eq r3.key?('type_regroupement_id')
  end

  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour get_regroupement" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r2 =  Annuaire.search_matiere 'Soutien'
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.search_matiere 'Soutien'
    expect( r2.key?('json_class') ).to eq r3.key?('json_class')
    expect( r2.key?('id') ).to eq r3.key?('id')
    expect( r2.key?('libelle_court') ).to eq r3.key?('libelle_court')
    expect( r2.key?('libelle_long') ).to eq r3.key?('libelle_long')
  end

  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour get_etablissement_regroupements" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r2 = Annuaire.get_etablissement_regroupements '0699990Z'
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.get_etablissement_regroupements '0699999Z'
    expect( r2.key?('classes') ).to eq r3.key?('classes')
    expect( r2.key?('groupes_eleves') ).to eq r3.key?('groupes_eleves')
    expect( r2.key?('groupes_libres') ).to eq r3.key?('groupes_libres')
  end

  # it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour search_regroupement" do
  #   ANNUAIRE[:api_mode] = 'v2'
  #   ANNUAIRE[:url] = @url_annuaire_v2
  #   r2 = Annuaire.search_regroupement '0699990Z', 'test_aaf24'
  #   ANNUAIRE[:api_mode] = 'v3'
  #   ANNUAIRE[:url] = @url_annuaire_v3
  #   r3 = Annuaire.search_regroupement '0699999Z', 'test'
  # end

  # it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour search_utilisateur" do
  #   ANNUAIRE[:api_mode] = 'v2'
  #   ANNUAIRE[:url] = @url_annuaire_v2
  #   Annuaire.set_search true
  #   r2 = Annuaire.search_utilisateur '0699990Z', 'Levallois', 'Pierre-Gilles'
  #   ANNUAIRE[:api_mode] = 'v3'
  #   ANNUAIRE[:url] = @url_annuaire_v3
  #   r3 = Annuaire.search_utilisateur '0699999Z', 'Levallois', 'Pierre-Gilles'
  #   #   r3.each { |k, v| puts "r2.key?('"+k.to_s+"').should be r3.key?('"+k.to_s+"')" }
  # end

  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour get_user_regroupements" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    Annuaire.set_search true
    r2 =  Annuaire.get_user_regroupements 'VPG60307'
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.get_user_regroupements 'VAA61315'
    r3.each { |k, _v| puts 'r2.key?(\'' + k.to_s + '\').should be r3.key?(\'' + k.to_s + '\')' }
    expect( r2.key?('classes') ).to eq r3.key?('classes')
    expect( r2.key?('groupes_eleves') ).to eq r3.key?('groupes_eleves')
    expect( r2.key?('groupes_libres') ).to eq r3.key?('groupes_libres')
  end
  #   r3.each { |k, v| puts "r2.key?('"+k.to_s+"').should be r3.key?('"+k.to_s+"')" }

end
