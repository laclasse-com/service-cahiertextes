# -*- coding: utf-8 -*-

require_relative '../models/models'
require_relative '../lib/pronote'

module CahierDeTextesAPI
  class ProNoteAPI < Grape::API
    format :json

    resource :pronote do

      resource :xml do
        desc "Upload a XML file and load it in DB."
        post do
          # Consommation du fichier reçu
          ProNote.load_XML( File.open( params[:xml_file][:tempfile] ) )

          # on retourne un log succint des infos chargées
          {
            filename: params[:xml_file][:filename],
            size: params[:xml_file][:tempfile].size,
            nb_salles: Salle.count,
            nb_plages_horaires: PlageHoraire.count,
            nb_creneau_emploi_du_temps: CreneauEmploiDuTemps.count,
          }
        end
      end

    end

  end
end
