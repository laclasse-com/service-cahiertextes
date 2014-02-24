# encoding: utf-8
# -*- coding: utf-8 -*-

require 'base64'
require 'cgi'
require 'openssl'

require_relative '../config/options'

# Module d'interfaçage avec l'annuaire
module Annuaire
  module_function

  def sign( uri, service, args, secret_key, app_id )
    timestamp = Time.now.getutc.strftime('%FT%T')
    canonical_string = "#{uri}/#{service}?"

    canonical_string += Hash[ args.sort ].map { |key, value| "#{key}=#{CGI.escape(value)}" }.join( '&' )
    canonical_string += ";#{timestamp};#{app_id}"

    digest = OpenSSL::Digest.new( 'sha1' )
    digested_message = Base64.encode64( OpenSSL::HMAC.digest( digest, secret_key, canonical_string ) )

    query = args.map { |key, value| "#{key}=#{CGI.escape(value)}" }.join( '&' )

    signature = { app_id: app_id,
                  timestamp: timestamp,
                  signature: digested_message }.map { |key, value| "#{key}=#{CGI.escape(value)}" }.join( ';' ).chomp

    "#{uri}/#{service}?#{query};#{signature}"
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
        return { 'id_ent' => 'VAA' + rand( 60_400 .. 60_500 ).to_s } # nil }
      end
    end
  end

  # API d'interfaçage avec l'annuaire à destination du client
  def get_matiere( id )
    id = URI.escape( id )

    RestClient.get( sign( ANNUAIRE[:url], "matieres/#{id}", {}, ANNUAIRE[:secret], ANNUAIRE[:app_id] ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )
      else
        STDERR.puts "Matière inconnue : #{id}"
      end
    end
  end

  def get_regroupement( id )
    id = URI.escape( id )

    RestClient.get( sign( ANNUAIRE[:url], "regroupements/#{id}", {}, ANNUAIRE[:secret], ANNUAIRE[:app_id] ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )
      else
        STDERR.puts "Regroupement inconnu : #{id}"
      end
    end
  end

  def get_user( id )
    id = URI.escape( id )

    RestClient.get( sign( ANNUAIRE[:url], "users/#{id}", { expand: 'true' }, ANNUAIRE[:secret], ANNUAIRE[:app_id] ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )
      else
        STDERR.puts "User inconnu : #{id}"
      end
    end
  end

  def get_etablissement( uai )
    uai = URI.escape( uai )

    RestClient.get( sign( ANNUAIRE[:url], "etablissements/#{uai}", { expand: 'true' }, ANNUAIRE[:secret], ANNUAIRE[:app_id] ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )
      else
        STDERR.puts "Établissement inconnu : #{uai}"
      end
    end
  end

end
