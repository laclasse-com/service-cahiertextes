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
    Annuaire.build_canonical_string(a).should == '?p1=v1&p2=v2;'
  end

  it 'should build an empty canonical string mode api V3' do
    ANNUAIRE[:api_mode] = 'v3'
    a = {}
    Annuaire.build_canonical_string(a).should == '?;' 
  end

  it 'should build a canonical string mode api V2' do
    ANNUAIRE[:api_mode] = 'v2'
    a = { p2: 'v2', p1: 'v1' }
    Annuaire.build_canonical_string(a).should == '&p1=v1&p2=v2;'
  end

  it 'should build an empty canonical string mode api V2' do
    ANNUAIRE[:api_mode] = 'v2'
    a = {}
    Annuaire.build_canonical_string(a).should == '&;'
  end

  it 'should sign the request in api V3 mode' do
    ANNUAIRE[:api_mode] = 'v3'
    signed_url = Annuaire.sign( @uri, @srv, @args )

    ts = CGI.unescape(signed_url.slice(/timestamp\=.*\;/)).sub('timestamp=', '').sub(';', '')

    canonical_string = "#{@uri}/#{@srv}"
    canonical_string += Annuaire.build_canonical_string( @args )

    canonical_string_to_sign = "#{canonical_string}#{ts};#{ANNUAIRE[:app_id]}"

    signature = Annuaire.build_signature( canonical_string_to_sign, ts )
    signed_url.should == "#{canonical_string}#{signature}"
  end

  it 'should sign the request in api V2 mode' do
    ANNUAIRE[:api_mode] = 'v2'
    @uri = 'http://www.dev.laclasse.com/pls/public/!ajax_server.service=ServiceApiUser&p_rendertype=none&uid='
    signed_url = Annuaire.sign(@uri, @srv, @args)
    ts = CGI.unescape(signed_url.slice(/timestamp\=.*\;/)).sub('timestamp=', '').sub(';', '')
    canonical_string = Annuaire.build_canonical_string(@args)
    signature = Annuaire.build_signature(canonical_string, ts)
    signed_url.should == "#{@uri}#{@srv}#{canonical_string}#{signature}"
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
    signed_url.should == "#{canonical_string}#{signature}"
  end

  it 'should sign the request in api V2 mode without args' do
    ANNUAIRE[:api_mode] = 'v2'
    @args = {}
    @uri = 'http://www.dev.laclasse.com/pls/public/!ajax_server.service=ServiceApiUser&p_rendertype=none&uid='
    signed_url = Annuaire.sign(@uri, @srv, @args)
    ts = CGI.unescape(signed_url.slice(/timestamp\=.*\;/)).sub('timestamp=', '').sub(';', '')
    canonical_string = Annuaire.build_canonical_string(@args)
    signature = Annuaire.build_signature(canonical_string, ts)
    signed_url.should == "#{@uri}#{@srv}#{canonical_string}#{signature}"
  end

  it ': function compat_service should return users/VAA60001 for users/VAA60001 service (mode V3)' do
    ANNUAIRE[:api_mode] = 'v3'
    Annuaire.compat_service(@srv).should == @srv
  end

  it ': function compat_service should return Users&uid=VAA60001 for users/VAA60001 service (mode V2)' do
    ANNUAIRE[:api_mode] = 'v2'
    Annuaire.compat_service(@srv).should == 'Users&uid=VAA60001'
  end

  it ': function compat_service should return etablissements/0699999Z for etablissements/0699999Z service (mode V3)' do
    ANNUAIRE[:api_mode] = 'v3'
    Annuaire.compat_service('etablissements/0699999Z').should == 'etablissements/0699999Z'
  end

  it ': function compat_service should return Etablissements&uai=0699999Z for etablissements/0699999Z service (mode V2)' do
    ANNUAIRE[:api_mode] = 'v2'
    Annuaire.compat_service('etablissements/0699999Z').should == 'Etablissements&uai=0699999Z'
  end

  it ': function compat_service should return matieres/1234 for matieres/1234 service (mode V3)' do
    ANNUAIRE[:api_mode] = 'v3'
    Annuaire.compat_service('matieres/1234').should == 'matieres/1234'
  end

  it ': function compat_service should return Matieres&code=1234 for matieres/1234 service (mode V2)' do
    ANNUAIRE[:api_mode] = 'v2'
    Annuaire.compat_service('matieres/1234').should == 'Matieres&code=1234'
  end

  it ': function compat_service should return matieres/libelle/MATH for matieres/libelle/MATH (mode V3)' do
    ANNUAIRE[:api_mode] = 'v3'
    Annuaire.compat_service('matieres/libelle/MATH').should == 'matieres/libelle/MATH'
  end

  it ': function compat_service should return Matieres&lib=MATH for matieres/libelle/MATH (mode V2)' do
    ANNUAIRE[:api_mode] = 'v2'
    Annuaire.set_search true
    Annuaire.compat_service('matieres/libelle/MATH').should == 'Matieres&lib=MATH'
  end

  it ': function compat_service should return regroupements/123 for regroupements/123 service (mode V3)' do
    ANNUAIRE[:api_mode] = 'v3'
    Annuaire.compat_service('regroupements/123').should == 'regroupements/123'
  end
 
  it ': function compat_service should return Regroupements&grp_id=123 for regroupements/123 service (mode V2)' do
    ANNUAIRE[:api_mode] = 'v2'
    Annuaire.set_search false
    Annuaire.compat_service('regroupements').should == 'Regroupements&grp_id='
  end

  it ': function compat_service should return regroupement/groupe1 for regroupement/groupe1 service (mode V3)' do
    ANNUAIRE[:api_mode] = 'v3'
    Annuaire.compat_service('regroupement/groupe1').should == 'regroupement/groupe1'
  end

  it ': function compat_service should return regroupement&etablissement=0699990Z&nom=groupe1 for regroupement/groupe1 service (mode V2)' do
    ANNUAIRE[:api_mode] = 'v2'
    Annuaire.set_search true
    Annuaire.compat_service('regroupement').should == 'regroupement'
  end

  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour get_user" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r2 = Annuaire.get_user "VPG60307"
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.get_user "VAA61315"
    
    r2.has_key?('id').should be r3.has_key?('id')
    r2.has_key?('id_sconet').should be r3.has_key?('id_sconet')
    r2.has_key?('id_jointure_aaf').should be r3.has_key?('id_jointure_aaf')
    r2.has_key?('login').should be r3.has_key?('login')
    r2.has_key?('nom').should be r3.has_key?('nom')
    r2.has_key?('prenom').should be r3.has_key?('prenom')
    r2.has_key?('sexe').should be r3.has_key?('sexe')
    r2.has_key?('id_ent').should be r3.has_key?('id_ent')
    r2.has_key?('date_naissance').should be r3.has_key?('date_naissance')
    r2.has_key?('adresse').should be r3.has_key?('adresse')
    r2.has_key?('code_postal').should be r3.has_key?('code_postal')
    r2.has_key?('ville').should be r3.has_key?('ville')
    r2.has_key?('avatar').should be r3.has_key?('avatar')
    r2.has_key?('full_name').should be r3.has_key?('full_name')
    r2.has_key?('profils').should be r3.has_key?('profils')
    r2.has_key?('telephones').should be r3.has_key?('telephones')
    r2.has_key?('emails').should be r3.has_key?('emails')
    
    #r3.each { |k, v| puts "r2.has_key?('"+k.to_s+"').should be r3.has_key?('"+k.to_s+"')" } 
  end
  
  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour get_etablissement" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r2 = Annuaire.get_etablissement "0699990Z"
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.get_etablissement "0699999Z"
    r2.has_key?('id').should be r3.has_key?('id')
    r2.has_key?('code_uai').should be r3.has_key?('code_uai')
    r2.has_key?('nom').should be r3.has_key?('nom')
    r2.has_key?('adresse').should be r3.has_key?('adresse')
    r2.has_key?('code_postal').should be r3.has_key?('code_postal')
    r2.has_key?('ville').should be r3.has_key?('ville')
    r2.has_key?('type_etablissement_id').should be r3.has_key?('type_etablissement_id')
    r2.has_key?('telephone').should be r3.has_key?('telephone')
    r2.has_key?('fax').should be r3.has_key?('fax')
    r2.has_key?('full_name').should be r3.has_key?('full_name')
    r2.has_key?('alimentation_state').should be r3.has_key?('alimentation_state')
    r2.has_key?('alimentation_date').should be r3.has_key?('alimentation_date')
    r2.has_key?('data_received').should be r3.has_key?('data_received')
    r2.has_key?('longitude').should be r3.has_key?('longitude')
    r2.has_key?('latitude').should be r3.has_key?('latitude')
    r2.has_key?('site_url').should be r3.has_key?('site_url')
    r2.has_key?('logo').should be r3.has_key?('logo')
    r2.has_key?('classes').should be r3.has_key?('classes')
    r2.has_key?('groupes_eleves').should be r3.has_key?('groupes_eleves')
    r2.has_key?('groupes_libres').should be r3.has_key?('groupes_libres')
    r2.has_key?('personnel').should be r3.has_key?('personnel')
    r2.has_key?('contacts').should be r3.has_key?('contacts')
    r2.has_key?('eleves').should be r3.has_key?('eleves')
    r2.has_key?('enseignants').should be r3.has_key?('enseignants')
    r2.has_key?('parents').should be r3.has_key?('parents')
  end
  
  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour get_matiere" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r2 =  Annuaire.get_matiere "001600"
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.get_matiere "001600"
    r2.has_key?('json_class').should be r3.has_key?('json_class')
    r2.has_key?('id').should be r3.has_key?('id')
    r2.has_key?('libelle_court').should be r3.has_key?('libelle_court')
    r2.has_key?('libelle_long').should be r3.has_key?('libelle_long')
  end
  
  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour get_regroupement" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r2 =  Annuaire.get_regroupement "1363"
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.get_regroupement "1363"
    r2.has_key?('id').should be r3.has_key?('id')
    r2.has_key?('etablissement_id').should be r3.has_key?('etablissement_id')
    r2.has_key?('libelle').should be r3.has_key?('libelle')
    r2.has_key?('libelle_aaf').should be r3.has_key?('libelle_aaf')
    r2.has_key?('type_regroupement_id').should be r3.has_key?('type_regroupement_id')
  end

  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour get_regroupement" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r2 =  Annuaire.search_matiere "Soutien"
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.search_matiere "Soutien"
    r2.has_key?('json_class').should be r3.has_key?('json_class')
    r2.has_key?('id').should be r3.has_key?('id')
    r2.has_key?('libelle_court').should be r3.has_key?('libelle_court')
    r2.has_key?('libelle_long').should be r3.has_key?('libelle_long')
  end
 
  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour get_etablissement_regroupements" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r2 = Annuaire.get_etablissement_regroupements "0699990Z"
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.get_etablissement_regroupements "0699999Z"
    r2.has_key?('classes').should be r3.has_key?('classes')
    r2.has_key?('groupes_eleves').should be r3.has_key?('groupes_eleves')
    r2.has_key?('groupes_libres').should be r3.has_key?('groupes_libres')
  end
 
  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour search_regroupement" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r2 = Annuaire.search_regroupement "0699990Z", "test_aaf24"  
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.search_regroupement "0699999Z", "test"     
  end
    
  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour search_utilisateur" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    Annuaire.set_search true
    r2 = Annuaire.search_utilisateur "0699990Z", "Levallois", "Pierre-Gilles"  
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.search_utilisateur "0699999Z", "Levallois", "Pierre-Gilles"  
    #   r3.each { |k, v| puts "r2.has_key?('"+k.to_s+"').should be r3.has_key?('"+k.to_s+"')" }
  end

  it " Compare les résultats des appels a l'annuaire en mode v2 et v3 pour get_user_regroupements" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    Annuaire.set_search true
    r2 =  Annuaire.get_user_regroupements "VPG60307" 
    ANNUAIRE[:api_mode] = 'v3'
    ANNUAIRE[:url] = @url_annuaire_v3
    r3 = Annuaire.get_user_regroupements "VAA61315"  
    r3.each { |k, v| puts "r2.has_key?('"+k.to_s+"').should be r3.has_key?('"+k.to_s+"')" }
    r2.has_key?('classes').should be r3.has_key?('classes')
    r2.has_key?('groupes_eleves').should be r3.has_key?('groupes_eleves')
    r2.has_key?('groupes_libres').should be r3.has_key?('groupes_libres')

  end
  #   r3.each { |k, v| puts "r2.has_key?('"+k.to_s+"').should be r3.has_key?('"+k.to_s+"')" }

end
  