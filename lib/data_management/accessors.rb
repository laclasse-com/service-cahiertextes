# -*- coding: utf-8 -*-

module DataManagement
  # Layer over models
  module Accessors
    module_function

    def create_or_get( model_class, params )
      objet = model_class.where( params ).first

      objet = model_class.create( params ) if objet.nil?
      objet.update( date_creation: Sequel::SQLTime.now ) if model_class.method_defined?( :date_creation )

      objet
    end
  end
end
