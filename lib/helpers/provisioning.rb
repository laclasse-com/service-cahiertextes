# -*- coding: utf-8 -*-

module CahierDeTextesApp
  module Helpers
    module Provisioning
      def provision( user )
        user[:user_detailed]['etablissements']
          .each { |etab|
          etablissement = Etablissement.where(UAI: etab[ 'code_uai' ]).first
          if etablissement.nil?
            etablissement = AnnuaireWrapper::Etablissement.get( etab[ 'code_uai' ] )
            Etablissement.create(UAI: etablissement['code_uai' ] )
            etablissement['classes']
              .concat( etablissement['groupes_eleves'] )
              .concat( etablissement['groupes_libres'] )
              .each {
              |regroupement|
              cdt = CahierDeTextes.where( regroupement_id: regroupement['id'] ).first
              CahierDeTextes.create( date_creation: Time.now,
                                     regroupement_id: regroupement['id'] ) if cdt.nil?
            }
          end
        }
      end
    end
  end
end
