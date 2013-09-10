# -*- coding: utf-8 -*-

require 'rest-client'           # https://github.com/rest-client/rest-client

# Module d'interfaçage avec l'annuaire
module Annuaire
  module_function

  SERVICE_ANNUAIRE_USER = 'http://www.dev.laclasse.com/api'

  def get_matiere_id( code_uai, label )
    RestClient.get( SERVICE_ANNUAIRE_USER + '/matieres',
                    { accept: 'json', params: { uai: code_uai, libelle: label } } ) do
      |response, request, result|
      if response.code == 200
        # TODO: use response
      else
        STDERR.puts response.code.to_s
      end
    end

    rand(100_000..999_999)
  end

  def get_regroupement_id( code_uai, nom )
    rand(100_000..999_999)
  end

  def get_utilisateur_id( code_uai, nom, prenom , date_de_naissance = nil )
    rand(100_000..999_999)
  end
end
