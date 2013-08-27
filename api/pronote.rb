# -*- coding: utf-8 -*-

require_relative '../models/models'
require_relative '../lib/pronote'

module CahierDeTextesAPI
  class ProNoteAPI < Grape::API
    format :json

    resource :pronote do
      
      get '/ping' do
        { ping: "pong" }
      end

      # POST
      desc "Upload an image."
      post 'upload_xml' do
        ProNote.load_XML(File.open(params[:xml_file][:tempfile]))

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
