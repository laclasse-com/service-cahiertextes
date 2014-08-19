# -*- coding: utf-8 -*-

require_relative '../../models/models'
require_relative '../../lib/pronote'
require_relative '../../lib/udt'

module CahierDeTextesAPI
  module V1
    class ImportAPI < Grape::API
      format :json

      desc 'Receive a Pronote XML file and load it in DB.'
      post '/pronote' do
        ProNote.load_xml( File.open( params[:xml_file][:tempfile] ) )

        # on retourne un log succint des infos chargées
        { filename: params[:xml_file][:filename],
          size: params[:xml_file][:tempfile].size,
          nb_salles: Salle.count,
          nb_plages_horaires: PlageHoraire.count,
          nb_creneau_emploi_du_temps: CreneauEmploiDuTemps.count }
      end

      desc 'Receive a UDT ZIP file and load it in DB.'
      params {
        requires :uai, desc: 'uai de l\'établissement envoyé'
      }
      post '/udt/uai/:uai' do
        UDT.load_zip( File.open( params[:file][:tempfile] ), params[ :uai ] )

        # on retourne un log succint des infos chargées
        { filename: params[:file][:filename],
          size: params[:file][:tempfile].size }
      end
    end
  end
end
