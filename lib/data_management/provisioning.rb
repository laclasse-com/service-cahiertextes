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
        user[:user_detailed]['profils']
          .each do |profil|
          etablissement = Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_v2_etablissements, "#{profil[ 'etablissement_code_uai' ]}", {} )
          next if etablissement == 'Not Found' || etablissement.key?( 'error' ) || etablissement.key?( :error )

          Accessors.create_or_get( Etablissement, UAI: etablissement[ 'uai' ] )

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
