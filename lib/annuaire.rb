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
      digested_message = Base64.encode64( OpenSSL::HMAC.digest( digest, ANNUAIRE[:secret], canonical_string ) )
      { app_id: ANNUAIRE[:app_id],
            timestamp: ts,
            signature: digested_message }.map { |key, value| "#{key}=#{CGI.escape(value)}" }.join( ';' ).chomp
   end

   # Compatibilité api V2, rectification du service
   # qui ne doit pas être au format REST, mais au format URL
   def compat_service (srv)
      if ANNUAIRE[:api_mode] == 'v2'
         srv.sub! 'matieres/libelle', '&searchmatiere='
         srv.sub! 'matieres', '&mat_code='
         srv.sub! 'etablissements', '&etb_code='
         srv.sub! 'regroupements', '&grp_id='
         srv.sub! 'users', ''
         srv.sub! 'regroupement', '&searchgrp='
         srv.sub! '/', ''
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
         |response, request, result|
         if response.code == 200
            return JSON.parse( response )
         else
            STDERR.puts "#{error_msg} : #{CGI.escape( param )}"
         end
      end
   end

   def search_matiere( label )
      label = URI.escape( label )

      RestClient.get( sign( ANNUAIRE[:url], "matieres/libelle/#{label}", {}, ANNUAIRE[:secret], ANNUAIRE[:app_id] ) ) do
         |response, request, result|
         if response.code == 200
            return JSON.parse( response )
         else
            STDERR.puts "Matière inconnue : #{label}"
            STDERR.puts 'URL fautive: ' + sign( ANNUAIRE[:url], "/matieres/libelle/#{label}", {}, ANNUAIRE[:secret], ANNUAIRE[:app_id] )
            return { 'id' => nil }
         end
      end
   end

   def search_regroupement( code_uai, nom )
      code_uai = URI.escape( code_uai )
      nom = URI.escape( nom )

      RestClient.get( sign( ANNUAIRE[:url], 'regroupement', { etablissement: code_uai, nom: nom }, ANNUAIRE[:secret], ANNUAIRE[:app_id] ) ) do
         |response, request, result|
         if response.code == 200
            return JSON.parse( response )[0]
         else
            STDERR.puts "Regroupement inconnu : #{nom}"
            return { 'id' => rand( 1 .. 59 ) } # nil }
         end
      end
   end

   def search_utilisateur( code_uai, nom, prenom )
      code_uai = URI.escape( code_uai )
      nom = URI.escape( nom )
      prenom = URI.escape( prenom )

      RestClient.get( sign( ANNUAIRE[:url], 'users', { nom: nom, prenom: prenom, etablissement: code_uai }, ANNUAIRE[:secret], ANNUAIRE[:app_id] ) ) do
         |response, request, result|
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
      parsed_response = send_request 'matieres', CGI.escape( id ), 'false', 'Matière inconnue'
      parsed_response
   end

   # Service classes et groupes d'élèves
   def get_regroupement( id )
      parsed_response = send_request 'regroupements', CGI.escape( id ), 'false', 'Regroupement inconnu'
      parsed_response
   end

   # Service Utilisateur : init de la session et de son environnement
   def get_user( id )
      parsed_response = send_request 'users', CGI.escape( id ), 'true', 'User inconnu'
      parsed_response
   end

   # Service etablissement
   def get_etablissement( uai )
      parsed_response = send_request 'etablissements', CGI.escape( uai ), 'true', 'Etablissement inconnu'
      parsed_response
   end

end
