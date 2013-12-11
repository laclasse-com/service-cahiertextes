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

    digest = OpenSSL::Digest::Digest.new( 'sha1' )
    digested_message = Base64.encode64( OpenSSL::HMAC.digest( digest, secret_key, canonical_string ) )

    query = args.map { |key, value| "#{key}=#{CGI.escape(value)}" }.join( '&' )

    signature = { app_id: app_id,
                  timestamp: timestamp,
                  signature: digested_message }.map { |key, value| "#{key}=#{CGI.escape(value)}" }.join( ';' ).chomp

    "#{uri}/#{service}?#{query};#{signature}"
  end

  def search_matiere( label )
    RestClient.get( sign( ANNUAIRE[:url], "/matieres/libelle/#{label}", {}, ANNUAIRE[:secret], ANNUAIRE[:app_id] ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )
      else
        STDERR.puts "Matière inconnue : #{label} ; l'annuaire a répondu #{response}"
        STDERR.puts 'URL fautive: ' + sign( ANNUAIRE[:url], "/matieres/libelle/#{label}", {}, ANNUAIRE[:secret], ANNUAIRE[:app_id] )
        return { 'id' => nil }
      end
    end
  end

  def search_regroupement( code_uai, nom )
    RestClient.get( sign( ANNUAIRE[:url], "/regroupement?etablissement=#{code_uai}nom=#{nom}", {}, ANNUAIRE[:secret], ANNUAIRE[:app_id] ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )[0]
      else
        STDERR.puts "Regroupement inconnu : #{nom} ; l'annuaire a répondu #{response}"
        return { 'id' => rand( 1 .. 59 ) } # nil }
      end
    end
  end

  def search_utilisateur( code_uai, nom, prenom )
    RestClient.get( sign( ANNUAIRE[:url], '/users', { nom: nom, prenom: prenom, etablissement: code_uai }, ANNUAIRE[:secret], ANNUAIRE[:app_id] ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )[0]
      else
        STDERR.puts "Utilisateur inconnu : #{prenom} #{nom} ; l'annuaire a répondu #{response}"
        return { 'id_ent' => 'VAA' + rand( 60_400 .. 60_500 ).to_s } # nil }
      end
    end
  end

  # API d'interfaçage avec l'annuaire à destination du client
  def get_matiere( id )
    RestClient.get( sign( ANNUAIRE[:url], "/matieres/#{id}", {}, ANNUAIRE[:secret], ANNUAIRE[:app_id] ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )
      else
        STDERR.puts "Matière inconnue : #{nom} ; l'annuaire a répondu #{response}"
      end
    end
  end

  def get_regroupement( id )
    RestClient.get( sign( ANNUAIRE[:url], "/regroupements/#{id}", {}, ANNUAIRE[:secret], ANNUAIRE[:app_id] ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )
      else
        STDERR.puts "Regroupement inconnu : #{nom} ; l'annuaire a répondu #{response}"
      end
    end
  end

  def get_user( id )
    RestClient.get( sign( ANNUAIRE[:url], "/users/#{id}", { expand: 'true' }, ANNUAIRE[:secret], ANNUAIRE[:app_id] ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )
      else
        STDERR.puts "User inconnu : #{nom} ; l'annuaire a répondu #{response}"
      end
    end
  end

end
