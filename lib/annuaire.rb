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
    
    def coordination
      @coordination
    end
  
    def liaison
      @liaison
    end
  
  # Fonction de vérification du mode d'api paramétrée dans la conf et init des paramètres
  def init
   @coordination = '?'
   @liaison = '/'
   if ANNUAIRE[:api_mode] == 'v2'
      @coordination = "&"
      @liaison = ""
    end
  end
  
  # Construire la chaine de paramètres à encoder
  def build_canonical_string(args)
    init
    s = Hash[ args.sort ].map { |key, value| "#{key}=#{CGI.escape(value)}" }.join( '&' )
    coordination + "#{s};"
  end
  
  # Construction de la signature 
  def build_signature(canonical_string, ts)
    digest = OpenSSL::Digest.new( 'sha1' )
    digested_message = Base64.encode64( OpenSSL::HMAC.digest( digest, ANNUAIRE[:secret], canonical_string ) )
    { app_id: ANNUAIRE[:app_id], 
      timestamp: ts,
      signature: digested_message }.map { |key, value| "#{key}=#{CGI.escape(value)}" }.join( ';' ).chomp
  end
  
  # Compatibilité api V2, rectification du service 
  # qui ne doit pas être au format REST, mais au format URL
  def compat_service (srv)
    if ANNUAIRE[:api_mode] == 'v2'
      srv.sub! "matieres/libelle", "&searchmatiere="
      srv.sub! "matieres", "&mat_code="
      srv.sub! "etablissements", "&etb_code="
      srv.sub! "regroupements", "&grp_id="
      srv.sub! "users", ""
      srv.sub! "regroupement", "&searchgrp="
      srv.sub! "/", ""
    end
    srv
  end
  
  # construction de la requete signée
  def sign( uri, service, args )
    init
    timestamp = Time.now.getutc.strftime('%FT%T')
    canonical_string = build_canonical_string args    
    query = args.map { |key, value| "#{key}=#{CGI.escape(value)}" }.join( '&' )
    signature = build_signature(canonical_string, timestamp)

    # Compatibilité avec les api laclasse v2 (pl/sql): pas de mode REST, en fait.
    service = compat_service service
    # Fin patch compat.
    
    "#{uri}"+liaison+"#{service}"+coordination+"#{query};#{signature}"
  end

  # Envoie de la requete à l'annuaire
  def send_request (service, param, expandvalue, error_msg)
    RestClient.get( sign( ANNUAIRE[:url], "#{service}/#{param}", { expand: expandvalue } ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )
      else
        STDERR.puts "#{error_msg} : #{param}"
      end
    end
   end

  # service de recherche d'une matière
  def search_matiere( label )
    parsed_response = send_request "matieres/libelle", CGI.escape( label ), "false", "Matière inconnue"
  end

  # Service de recherche d'une classe ou d'un groupe d'élèves
  def search_regroupement( code_uai, nom )
    code_uai = CGI.escape( code_uai )
    nom = CGI.escape( nom )

    RestClient.get( sign( ANNUAIRE[:url], 'regroupement', { etablissement: code_uai, nom: nom }) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )[0]
      else
        STDERR.puts "Regroupement inconnu : #{nom}"
        return { 'id' => rand( 1 .. 59 ) } # nil }
      end
    end
  end

  # Service de recherche d'un utilisateur
  def search_utilisateur( code_uai, nom, prenom )
    code_uai = CGI.escape( code_uai )
    nom = CGI.escape( nom )
    prenom = CGI.escape( prenom )

    RestClient.get( sign( ANNUAIRE[:url], 'users', { nom: nom, prenom: prenom, etablissement: code_uai } ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )[0]
      else
        STDERR.puts "Utilisateur inconnu : #{prenom} #{nom}"
        return { 'id_ent' => 'VAA' + rand( 60_400 .. 60_500 ).to_s } # nil }
      end
    end
  end

  # API d'interfaçage avec l'annuaire à destination du client
  def get_matiere( id )
    parsed_response = send_request "matieres", CGI.escape( id ), "false", "Matière inconnue"
  end
  
  # Service classes et groupes d'élèves
  def get_regroupement( id )
    parsed_response = send_request "regroupements", CGI.escape( id ), "false", "Regroupement inconnu"
  end

  # Service Utilisateur : init de la session et de son environnement
  def get_user( id )
    parsed_response = send_request "users", CGI.escape( id ), "true", "User inconnu"
  end

  # Service etablissement
  def get_etablissement( uai )
    parsed_response = send_request "etablissements", CGI.escape( uai ), "true", "Etablissement inconnu"
  end

end