# -*- coding: utf-8 -*-

require_relative '../lib/annuaire'

module CahierDeTextesAPI
   class CahiersDeTextesAPI < Grape::API

      desc 'contenu combiné des cahiers de textes concernant l\'utilisateur durant l\'intervalle de dates donné'
      params {
         optional :debut, type: Time
         optional :fin, type: Time
      }
      get  do
         # TODO: prendre en compte debut et fin

         regroupements_ids = user.classes.map {
            |classe|
            classe['classe_id']
         }.uniq

         regroupements_ids.map {
            |regroupement_id|
            cdt = CahierDeTextes[ regroupement_id: regroupement_id ]
            unless cdt.nil?
               CahierDeTextes[ regroupement_id: regroupement_id ].contenu( params[:debut] ? params[:debut] : Time.now,
                                                                           params[:fin] ? params[:fin] : Time.now )
            end
         }
      end

   end
end
