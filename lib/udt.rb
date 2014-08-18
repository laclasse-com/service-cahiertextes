# -*- coding: utf-8 -*-
require 'nokogiri'
require 'zip'

require_relative './annuaire'
require_relative '../models/models'

# Consomme le fichier Emploi du temps exporté par Pronote
module UDT
  module_function

  def load_zip( zip )
    zip_file = Zip::File.open( zip )
    semaines = zip_file.glob( 'semaines.xml' ).first
    p semaines
  end
end
