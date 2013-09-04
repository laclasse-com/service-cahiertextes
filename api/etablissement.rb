# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class EtablissementAPI < Grape::API
    format :json

    resource :classes do
      desc 'statistiques des cahiers de textes par classes/mois/matières'
      get do
        # TODO: get this from actual (Principal) user
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
        requires :class_id
      }
      get do
        CahierDeTextes[ regroupement_id: params[:id] ] &&
          CahierDeTextes[ regroupement_id: params[:id] ].statistics.to_json ||
          error!( 'Classe inconnue', 404 )
      end

      desc 'valide toutes les saisies non validées de la classe'
      params {
        requires :classe_id
      }
      put '/:classe_id' do
        # TODO: validate all?
      end
    end

    resource :enseignants do
      desc 'statistiques des cahiers de textes par enseignants/mois'
      get do
        # TODO
      end
    end

    resource :enseignant do
      desc 'statistiques des cahiers de textes d\'un enseignant par mois/classes'
      params {
        requires :classe_id
      }
      get do
        # TODO
      end

      desc 'valide toutes les saisies non validées de l\'enseignant'
      params {
        requires :enseignant_id
      }
      put '/:enseignant_id' do
        # TODO: validate all?
      end
    end

  end
end
