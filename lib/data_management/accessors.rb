# -*- coding: utf-8 -*-

module DataManagement
  # Layer over models
  module Accessors
    module_function

    def create_or_get( classe, params )
      objet = classe.where( params ).first

      objet = classe.create( params ) if objet.nil?
      objet.update( date_creation: Time.now ) if classe.method_defined? :date_creation

      objet
    end
  end
end
