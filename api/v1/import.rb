# -*- coding: utf-8 -*-

require_relative '../../models/models'
require_relative '../../lib/pronote'
require_relative '../../lib/udt'

module CahierDeTextesAPI
  module V1
    class ImportAPI < Grape::API
      format :json

      before do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'DIR' )
      end

      desc 'Receive a Pronote XML file and load it in DB.'
      post '/pronote' do
        # on retourne un log succint des infos chargées
        { filename: params[:file][:filename],
          size: params[:file][:tempfile].size,
          rapport: ProNote.load_xml( File.open( params[:file][:tempfile] ) ) }
      end

      desc 'Receive a UDT ZIP file and load it in DB.'
      params {
        requires :uai, desc: 'uai de l\'établissement envoyé'
      }
      post '/udt/uai/:uai' do
        { filename: params[:file][:filename],
          size: params[:file][:tempfile].size,
          rapport: UDT.load_zip( File.open( params[:file][:tempfile] ), params[ :uai ] ) }
      end

      desc 'Identifie une Matière/Regroupement/Personne-Non-Identifié en lui donnant un ID Annuaire manuellement'
      params {
        requires :sha256
        requires :id_annuaire
      }
      put '/mrpni/:sha256/est/:id_annuaire' do
        fi = FailedIdentification.where( sha256: params[:sha256] ).first
        unless fi.nil?
          fi.update( id_annuaire: params[:id_annuaire] )
          fi.save
        end

        fi
      end
    end
  end
end
