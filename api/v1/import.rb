# -*- coding: utf-8 -*-

require_relative '../../models/models'
require_relative '../../lib/pronote'
require_relative '../../lib/utils/xml_to_hash'

module CahierDeTextesAPI
  module V1
    class ImportAPI < Grape::API
      format :json

      before do
        user_needs_to_be( %w( DIR ), true )
      end

      desc 'Receive a Pronote XML file and load it in DB.'
      params do
        requires :file

        optional :create_creneaux
      end
      post '/pronote' do
        uai = ProNote.extract_uai_from_xml( File.open( params[:file][:tempfile] ) )

        create_creneaux = params.key?( :create_creneaux ) ? params[:create_creneaux] == 'true' : true

        error!( '401 Unauthorized', 401 ) unless user_is_profils_in_etablissement?( %w( DIR ENS DOC ), uai )

        # on retourne un log succint des infos chargées
        { filename: params[:file][:filename],
          size: params[:file][:tempfile].size,
          create_creneaux: create_creneaux,
          rapport: ProNote.decrypt_and_load_xml( File.open( params[:file][:tempfile] ),
                                                 create_creneaux ) }
      end

      desc 'Receive a Pronote XML file, decrypt it and send it back a JSON.'
      params do
        requires :file
      end
      post '/pronote/decrypt' do
        uai = ProNote.extract_uai_from_xml( File.open( params[:file][:tempfile] ) )

        error!( '401 Unauthorized', 401 ) unless user_is_profils_in_etablissement?( %w( DIR ENS DOC ), uai )

        Hash.from_xml( ProNote.decrypt_xml(  File.open( params[:file][:tempfile] ) ) )
      end

      desc 'Identifie une Matière/Regroupement/Personne-Non-Identifié en lui donnant un ID Annuaire manuellement'
      params do
        requires :sha256
        requires :id_annuaire
      end
      put '/mrpni/:sha256/est/:id_annuaire' do
        user_needs_to_be( %w( DIR ENS DOC ), true )

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
