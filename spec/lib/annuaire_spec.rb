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

  it " teste l'appel a l'annuaire  en mode v2 pour get_user" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r = Annuaire.get_user "VPG60307"

    r.class.should be Hash 
    r.has_key?('id').should be true
    r.has_key?('nom').should be true
    r.has_key?('prenom').should be true
    r.has_key?('sexe').should be true
    r.has_key?('id_ent').should be true
    r.has_key?('date_naissance').should be true
    r.has_key?('adresse').should be true
    r.has_key?('code_postal').should be true
    r.has_key?('ville').should be true
    r.has_key?('full_name').should be true
    r.has_key?('profils').should be true
    r.has_key?('telephones').should be true
    r.has_key?('emails').should be true  

  end
  
  it " teste l'appel a l'annuaire  en mode v2 pour get_etablissement" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r = Annuaire.get_etablissement "0699990Z"
 
    r.has_key?('id').should be true
    r.has_key?('nom').should be true
    r.has_key?('full_name').should be true
    r.has_key?('adresse').should be true
    r.has_key?('code_postal').should be true
    r.has_key?('telephone').should be true
    r.has_key?('fax').should be true
    r.has_key?('site_url').should be true
    r.has_key?('type_etalissement_id').should be true
    r.has_key?('code_uai').should be true
    r.has_key?('ville').should be true
    r.has_key?('latitude').should be true
    r.has_key?('longitude').should be true
    r.has_key?('logo').should be true
    r.has_key?('alimentation_state').should be true
    r.has_key?('data_recieved').should be true
    r.has_key?('alimentation_date').should be true
    r.has_key?('classes').should be true
    r.has_key?('groupes_eleves').should be true
    r.has_key?('groupes_libres').should be true
    r.has_key?('personnel').should be true
    r.has_key?('eleves').should be true
    r.has_key?('enseignants').should be true
    r.has_key?('parents').should be true

  end

  it " teste l'appel a l'annuaire  en mode v2 pour get_matiere" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r =  Annuaire.get_matiere "001600"
    r.has_key?('json_class').should be true
    r['json_class'].should == "MatiereEnseignee"
    r.has_key?('id').should be true
    r.has_key?('libelle_court').should be true
    r.has_key?('libelle_long').should be true     
  end

  it " teste l'appel a l'annuaire  en mode v2 pour get_regroupement" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r =  Annuaire.get_regroupement "1363"
    r.has_key?('id').should be true
    r.has_key?('etablissement_id').should be true
    r.has_key?('libelle').should be true
    r.has_key?('libelle_aaf').should be true
    r.has_key?('type_regroupement_id').should be true
  end

  it " teste l'appel a l'annuaire  en mode v2 pour search_matiere" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r =  Annuaire.search_matiere "Soutien"
    r.has_key?('json_class').should be true
    r.has_key?('id').should be true
    r.has_key?('libelle_court').should be true
    r.has_key?('libelle_long').should be true 
  end

  it " teste l'appel a l'annuaire  en mode v2 pour search_regroupement" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r = Annuaire.search_regroupement "0699990Z", "test_aaf24"  
  end
    
  it " teste l'appel a l'annuaire  en mode v2 pour search_utilisateur" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    Annuaire.set_search true
    r = Annuaire.search_utilisateur "0699990Z", "Levallois", "Pierre-Gilles"  
  end

  it " teste l'appel a l'annuaire  en mode v2 pour get_etablissement_regroupements" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    r = Annuaire.get_etablissement_regroupements "0699990Z"
    r.has_key?('id').should be true
    r.has_key?('nom').should be true
    r.has_key?('full_name').should be true
    r.has_key?('adresse').should be true
    r.has_key?('code_postal').should be true
    r.has_key?('telephone').should be true
    r.has_key?('fax').should be true
    r.has_key?('site_url').should be true
    r.has_key?('type_etalissement_id').should be true
    r.has_key?('code_uai').should be true
    r.has_key?('ville').should be true
    r.has_key?('latitude').should be true
    r.has_key?('longitude').should be true
    r.has_key?('logo').should be true
    r.has_key?('alimentation_state').should be true
    r.has_key?('data_recieved').should be true
    r.has_key?('alimentation_date').should be true
    r.has_key?('classes').should be true
    r.has_key?('groupes_eleves').should be true
    r.has_key?('groupes_libres').should be true
    r.has_key?('personnel').should be true
    r.has_key?('eleves').should be true
    r.has_key?('enseignants').should be true
    r.has_key?('parents').should be true
  end

  it " teste l'appel a l'annuaire  en mode v2 pour get_user_regroupements" do
    ANNUAIRE[:api_mode] = 'v2'
    ANNUAIRE[:url] = @url_annuaire_v2
    Annuaire.set_search true
    r =  Annuaire.get_user_regroupements "VPG60307" 
    r.has_key?('id').should be true
    r.has_key?('nom').should be true
    r.has_key?('prenom').should be true
    r.has_key?('sexe').should be true
    r.has_key?('id_ent').should be true
    r.has_key?('date_naissance').should be true
    r.has_key?('adresse').should be true
    r.has_key?('code_postal').should be true
    r.has_key?('ville').should be true
    r.has_key?('full_name').should be true
    r.has_key?('profils').should be true
    r.has_key?('telephones').should be true
    r.has_key?('emails').should be true
    r.has_key?('roles').should be true
    r.has_key?('classes').should be true
    r.has_key?('groupes_eleves').should be true
    r.has_key?('groupes_libres').should be true
  end

  # r.each { |k, v| puts "r.has_key?('"+k.to_s+"').should be true" }
  #        
  #      
  #      
  #      
  #      
  #      
  #      
  #     

end
 