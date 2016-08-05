# -*- coding: utf-8 -*-

module DataManagement
  # Layer over models
  module Accessors
    module_function

    def create_or_get( model_class, params )
      objet = model_class.where( params ).first

      if objet.nil?
        params[:date_creation] = Time.now if model_class.method_defined?( :date_creation )
        objet = model_class.create( params )
      end

      objet
    end
  end
end
