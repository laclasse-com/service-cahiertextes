# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class Etablissement < Grape::API
    format :json

    resource :etablissement do

      resource :plage_horaire do
        # GET http://localhost:9292/etablissement/plage_horaire/3
        desc 'Renvoi une plage horaire'
        params do
          requires :label, type: String, desc: 'label de la plage horaire'
        end
        route_param :label do
          get do
            PlageHoraire.filter(:label => params[:label])  # FIXME: only_time not enforced in json output
          end
        end
      end

      resource :salle do
        # GET http://localhost:9292/etablissement/salle/15519
        desc 'Renvoi une salle'
        params do
          requires :identifiant, type: String, desc: 'identifiant de la salle'
        end
        route_param :identifiant do
          get do
            Salle.filter(identifiant: params[:identifiant])
          end
        end
      end

    end

  end
end
