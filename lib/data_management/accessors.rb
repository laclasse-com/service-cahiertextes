module DataManagement
  module Accessors
    module_function

    def create_or_get( model_class, params )
      objet = model_class.where( params ).first

      if objet.nil?
        params[:ctime] = Time.now if model_class.method_defined?( :ctime )
        objet = model_class.create( params )
      end

      objet
    end
  end
end
