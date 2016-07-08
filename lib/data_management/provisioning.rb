# -*- coding: utf-8 -*-

module DataManagement
  # Layer over models
  module Provisioning
    module_function

    def provision( user )
      if user[:user_detailed].nil? || user[:user_detailed]['etablissements'].nil?
        LOGGER.warn 'user has no etablissements defined'
        LOGGER.warn user.to_s
      else
        user[:user_detailed]['etablissements']
          .each do |etab|
          etablissement = AnnuaireWrapper::Etablissement.get( etab[ 'code_uai' ], 2 )
          next if etablissement == 'Not Found' || etablissement.key?( 'error' ) || etablissement.key?( :error )

          Accessors.create_or_get( Etablissement, UAI: etab[ 'code_uai' ] )

          etablissement['groups']
            .each do |regroupement|
            Accessors.create_or_get( CahierDeTextes,
                                     regroupement_id: regroupement['id'] )
          end
        end
      end
    end
  end
end
