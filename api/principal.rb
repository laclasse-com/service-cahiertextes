# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class PrincipalAPI < Grape::API
    format :json

    resource :principal do

      resource :classes do
        desc 'statistiques des cahiers de textes par classes/mois/matières'
        get do
          #TODO: get this from actual (Principal) user
          regroupements_ids = [ 1, 2, 3, 4, 5, 12 ]

          regroupements_ids.map {
            |regroupement_id|
            CahierDeTextes[regroupement_id: regroupement_id].statistics
          }.to_json
        end
      end

      resource :classe do
        desc 'statistiques du cahier de textes d\'une classe'
        params {
          requires :id, type: Integer
        }
        get do
          CahierDeTextes[ regroupement_id: params[:id] ] &&
            CahierDeTextes[ regroupement_id: params[:id] ].statistics.to_json ||
            error!( 'Classe inconnue', 404 )
        end
        post do
          # TODO: validate all?
        end
      end

      resource :enseignants do
        desc 'statistiques des cahiers de textes par enseignants/mois'
        # TODO
      end

      resource :enseignant do
        desc 'statistiques des cahiers de textes d\'un enseignant par mois/classes'
        # TODO
      end

    end

  end
end
