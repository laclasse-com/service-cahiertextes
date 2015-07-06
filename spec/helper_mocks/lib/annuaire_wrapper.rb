module AnnuaireWrapper
  module Matiere
    module_function

    def search( _label )
      { 'id' => nil }
    end
  end

  module Etablissement
    module User
      module_function

      def search( _uai, _nom, _prenom )
        nil
      end
    end
    module Regroupement
      module_function

      def search( _uai, _nom )
        nil
      end
    end
  end
end
