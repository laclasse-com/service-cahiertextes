# -*- coding: utf-8 -*-

require 'rest-client'

module Annuaire
  module_function

  def get_matiere_id
    rand(100_000..999_999)
  end

  def get_regroupement_id
    rand(100_000..999_999)
  end

  def get_utilisateur_id
    rand(100_000..999_999)
  end
end
