# encoding: utf-8
# -*- coding: utf-8 -*-

require 'base64'
require 'cgi'
require 'openssl'

require_relative '../config/options'

# Module d'interfaçage avec l'annuaire
module Annuaire
  module_function

  @coordination = nil
  @liaison = nil
  @search = false

  # Petit setter pour les tests unitaires
  def set_search(arg)
    @search=arg
  end

  # Fonction de vérification du mode d'api paramétrée dans la conf et init des paramètres
  def init
    @coordination = '?'
    @liaison = '/'
    if ANNUAIRE[:api_mode] == 'v2'
      @coordination = '&'
      @liaison = ''
    end
  end

  # Construire la chaine de paramètres à encoder
  def build_canonical_string(args)
    init
    s = Hash[ args.sort ].map { |key, value| "#{key}=#{CGI.escape(value)}" }.join( '&' )

    "#{@coordination}#{s};"
  end

  # Construction de la signature
  def build_signature(canonical_string, ts)
    digest = OpenSSL::Digest.new( 'sha1' )
    digested_message = Base64.encode64( OpenSSL::HMAC.digest( digest, ANNUAIRE[:api_key], canonical_string ) )
    { app_id: ANNUAIRE[:app_id],
      timestamp: ts,
      signature: digested_message }.map { |key, value| "#{key}=#{CGI.escape(value)}" }.join( ';' ).chomp
  end

  # Compatibilité api V2, rectification du service
  # qui ne doit pas être au format REST, mais au format URL
  def compat_service(srv)
    if ANNUAIRE[:api_mode] == 'v2'
      if @search
        srv.sub! 'users', 'SearchUsers&uid='
        srv.sub! 'matieres/libelle', 'Matieres&lib='
      else
        srv.sub! 'users', 'Users&uid='
        srv.sub! 'etablissements', 'Etablissements&uai='
        srv.sub! 'matieres', 'Matieres&code='
        srv.sub! 'regroupements', 'Regroupements&grp_id='
        # En dernier pour traiter les cas des etab/[uai]/Regroupements et users/[uid]/Regroupements
        # Les services Users et Etablissements, donnent l'info des regroupements en mode expand.
        srv.sub! '/Regroupements&grp_id=', '&expand=true' if ( !srv.match('Users&uid=').nil? || !srv.match('Etablissements&uai=').nil? )
      end
      srv.sub! '/', '' # Supprimer les '/' devant les data : &grp_id=/19 devient &grp_id=19
    end
    srv
  end

  def sign( uri, service, args )
    init
    timestamp = Time.now.getutc.strftime('%FT%T')
    canonical_string = ANNUAIRE[:api_mode] == 'v3' ? "#{uri}#{@liaison}#{service}" : ''
    canonical_string += build_canonical_string( args )
    canonical_string += "#{timestamp};#{ANNUAIRE[:app_id]}" if ANNUAIRE[:api_mode] == 'v3'

    signature = build_signature( canonical_string, timestamp )

    # Compatibilité avec les api laclasse v2 (pl/sql): pas de mode REST, en fait.
    service = compat_service( service )
    # Fin patch compat.

    query = args.map { |key, value| "#{key}=#{CGI.escape(value)}" }.join( '&' )

    "#{uri}#{@liaison}#{service}#{@coordination}#{query};#{signature}"
  end

  def send_request( service, param, expand, error_msg )
    RestClient.get( sign( ANNUAIRE[:url], "#{service}/#{CGI.escape( param )}", { expand: expand } ) ) do
      |response, _request, _result|
      if response.code == 200
        return JSON.parse( response )
      else
        STDERR.puts "#{error_msg} : #{CGI.escape( param )}"
      end
    end
  end

  def search_matiere( label )
    label = URI.escape( label )
    @search = true
    RestClient.get( sign( ANNUAIRE[:url], "matieres/libelle/#{label}", {} ) ) do
      |response, _request, _result|
      if response.code == 200
        return JSON.parse( response )
      else
        STDERR.puts "Matière inconnue : #{label}"
        STDERR.puts 'URL fautive: ' + sign( ANNUAIRE[:url], "/matieres/libelle/#{label}", {} )
        return { 'id' => nil }
      end
    end
  end

  def search_regroupement( code_uai, nom )
    code_uai = URI.escape( code_uai )
    nom = URI.escape( nom )
    @search = true
    RestClient.get( sign( ANNUAIRE[:url], 'regroupement', { etablissement: code_uai, nom: nom, expand: "false" } ) ) do
      |response, _request, _result|
      if response.code == 200
        return JSON.parse( response )[0]
      else
        STDERR.puts "Regroupement inconnu : #{nom}"
        return { 'id' => nil }
      end
    end
  end

  def search_utilisateur( code_uai, nom, prenom )
    code_uai = URI.escape( code_uai )
    nom = URI.escape( nom )
    prenom = URI.escape( prenom )
    @search = true
    RestClient.get( sign( ANNUAIRE[:url], 'users', { nom: nom, prenom: prenom, etablissement: code_uai } ) ) do
      |response, _request, _result|
      if response.code == 200
        return JSON.parse( response )[0]
      else
        STDERR.puts "Utilisateur inconnu : #{prenom} #{nom}"
        return { 'id_ent' => nil }
      end
    end
  end

  # API d'interfaçage avec l'annuaire à destination du client
  def get_matiere( id )
    @search = false
    send_request 'matieres', CGI.escape( id ), 'false', 'Matière inconnue'
  end

  # Service classes et groupes d'élèves
  def get_regroupement( id )
    @search = false
    send_request 'regroupements', CGI.escape( id ), 'false', 'Regroupement inconnu'
  end

  # Service Utilisateur : init de la session et de son environnement
  def get_user( id )
    @search = false
    send_request 'users', CGI.escape( id ), 'true', 'User inconnu'
  end

  def get_user_regroupements( id )
    @search = false
    RestClient.get( sign( ANNUAIRE[:url], "users/#{CGI.escape( id )}/regroupements", {} ) ) do
      |response, _request, _result|
      if response.code == 200
        return JSON.parse( response )
      else
        STDERR.puts "erreur getting user's regroupements : #{CGI.escape( id )}"
      end
    end
  end

  # Service etablissement
  def get_etablissement( uai )
    @search = false
    send_request 'etablissements', CGI.escape( uai ), 'true', 'Etablissement inconnu'
  end

  def get_etablissement_regroupements( uai )
    @search = false
    RestClient.get( sign( ANNUAIRE[:url], "etablissements/#{CGI.escape( uai )}/regroupements", {} ) ) do
      |response, _request, _result|
      if response.code == 200
        return JSON.parse( response )
      else
        STDERR.puts "erreur getting etablissement's regroupements : #{CGI.escape( uai )}"
      end
    end
  end
end
