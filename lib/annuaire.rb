# -*- coding: utf-8 -*-

require 'rest-client'

# Module d'interfaçage avec l'annuaire
module Annuaire
  module_function

  def get_matiere_id( code_uai, label )
    rand(100_000..999_999)
  end

  def get_regroupement_id( code_uai, nom )
    rand(100_000..999_999)
  end

  def get_utilisateur_id( code_uai, nom, prenom , date_de_naissance = nil )
    rand(100_000..999_999)
  end
end
