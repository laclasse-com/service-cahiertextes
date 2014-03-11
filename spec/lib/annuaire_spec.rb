# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

require_relative '../../lib/annuaire'

describe Annuaire do
  before(:each) do
    @uri = 'http://localhost'
    @srv = 'users/VAA60001'
    @args = { expand: 'true' }
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

  it ': function compat_service should return VAA60001 for users/VAA60001 service (mode V2)' do
    ANNUAIRE[:api_mode] = 'v2'
    Annuaire.compat_service(@srv).should == 'VAA60001'
  end

  it ': function compat_service should return etablissements/0699999Z for etablissements/0699999Z service (mode V3)' do
    ANNUAIRE[:api_mode] = 'v3'
    Annuaire.compat_service('etablissements/0699999Z').should == 'etablissements/0699999Z'
  end

  it ': function compat_service should return &etb_code=0699999Zfor etablissements/0699999Z service (mode V2)' do
     ANNUAIRE[:api_mode] = 'v2'
     Annuaire.compat_service('etablissements/0699999Z').should == '&etb_code=0699999Z'
  end

  it ': function compat_service should return matieres/1234 for matieres/1234 service (mode V3)' do
     ANNUAIRE[:api_mode] = 'v3'
     Annuaire.compat_service('matieres/1234').should == 'matieres/1234'
  end

  it ': function compat_service should return &mat_code=1234 for matieres/1234 service (mode V2)' do
     ANNUAIRE[:api_mode] = 'v2'
     Annuaire.compat_service('matieres/1234').should == '&mat_code=1234'
  end

  it ': function compat_service should return matieres/libelle/MATH for matieres/libelle/MATH (mode V3)' do
     ANNUAIRE[:api_mode] = 'v3'
     Annuaire.compat_service('matieres/libelle/MATH').should == 'matieres/libelle/MATH'
  end

  it ': function compat_service should return &searchmatiere=MATH for matieres/libelle/MATH (mode V2)' do
     ANNUAIRE[:api_mode] = 'v2'
     Annuaire.compat_service('matieres/libelle/MATH').should == '&searchmatiere=MATH'
  end

  it ': function compat_service should return regroupements/123 for regroupements/123 service (mode V3)' do
     ANNUAIRE[:api_mode] = 'v3'
     Annuaire.compat_service('regroupements/123').should == 'regroupements/123'
  end

  it ': function compat_service should return &grp_id=123 for regroupements/123 service (mode V2)' do
     ANNUAIRE[:api_mode] = 'v2'
     Annuaire.compat_service('regroupements/123').should == '&grp_id=123'
  end

  it ': function compat_service should return regroupement/groupe1 for regroupement/groupe1 service (mode V3)' do
     ANNUAIRE[:api_mode] = 'v3'
     Annuaire.compat_service('regroupement/groupe1').should == 'regroupement/groupe1'
  end

  it ': function compat_service should return &searchgrp=groupe1 for regroupement/groupe1 service (mode V2)' do
     ANNUAIRE[:api_mode] = 'v2'
     Annuaire.compat_service('regroupement/groupe1').should == '&searchgrp=groupe1'
  end

end
