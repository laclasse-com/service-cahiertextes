# -*- coding: utf-8 -*-

module DataManagement
  # Layer over models
  module Provisioning
    module_function

    def provision( user )
      user[:user_detailed]['etablissements'].each {  |etablissement| Accessors.create_or_get( Etablissement, UAI: etablissement[ 'code_uai' ] ) } unless user[:user_detailed]['etablissements'].nil?

      user[:user_detailed]['classes'].each { |regroupement| Accessors.create_or_get( CahierDeTextes, regroupement_id: regroupement['classe_id'] )  } unless user[:user_detailed]['classes'].nil?

      user[:user_detailed]['groupes_eleves'].each { |regroupement| Accessors.create_or_get( CahierDeTextes, regroupement_id: regroupement['groupe_id'] )  } unless user[:user_detailed]['groupes_eleves'].nil?
    end
  end
end
