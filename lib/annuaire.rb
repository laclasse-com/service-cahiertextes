# -*- coding: utf-8 -*-

require 'open-uri'
require 'rest-client'           # https://github.com/rest-client/rest-client

# Module d'interfaçage avec l'annuaire
module Annuaire
  module_function

  URL_ANNUAIRE = 'http://www.dev.laclasse.com/api/app'

  def get_matiere( label )
    RestClient.get( URI.encode( "#{URL_ANNUAIRE}/matieres/libelle/#{label}" ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )
      else
        STDERR.puts "Matière inconnue : #{label} ; l'annuaire a répondu #{response}"
        return { 'id' => nil }
      end
    end
  end

  def get_regroupement_id( code_uai, nom )
    RestClient.get( URI.encode( "#{URL_ANNUAIRE}/regroupement?etablissement=#{code_uai}nom=#{nom}" ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )[0]
      else
        STDERR.puts "Regroupement inconnu : #{nom} ; l'annuaire a répondu #{response}"
        return { 'id' => rand( 1 .. 59 ) } # nil }
      end
    end
  end

  def get_utilisateur_id( code_uai, nom, prenom )
    RestClient.get( URI.encode( "#{URL_ANNUAIRE}/users?nom=#{nom}&prenom=#{prenom}&etablissement=#{code_uai}" ) ) do
      |response, request, result|
      if response.code == 200
        return JSON.parse( response )[0]
      else
        STDERR.puts "Utilisateur inconnu : #{prenom} #{nom} ; l'annuaire a répondu #{response}"
        return { 'id_ent' => 'VAA' + rand( 60_400 .. 60_500 ).to_s } # nil }
      end
    end
  end
end
