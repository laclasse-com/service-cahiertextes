# -*- coding: utf-8 -*-

require_relative '../../lib/pronote'
require_relative '../../lib/utils/xml_to_hash'
require_relative '../../models/import'

module CahierDeTextesApp
  module Routes
    module Api
      module ImportAPI
        def self.registered( app )
          app.get '/api/import/:id/?' do
            json( Import[ params[:id] ] )
          end

          app.get '/api/import/:id/creneaux/?' do
            import = Import[ params[:id] ]

            json CreneauEmploiDuTemps.where( etablissement_id: import.etablissement_id )
                                     .where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= DATE_FORMAT( import.date_import, '%Y-%m-%d') AND DATE_FORMAT( date_creation, '%Y-%m-%d') < '#{import.date_import + 10.minutes}'" ) )
                                     .all
          end

          app.post '/api/import/log/start/?' do
            etablissement = Etablissement.where(uai: params[:uai]).first

            halt( 404, "Établissement #{params[:uai]} inconnu" ) if etablissement.nil?

            json( Import.create( etablissement_id: etablissement.id,
                                 date_import: Sequel::SQLTime.now,
                                 type: params.key?( :type ) ? params[:type] : '',
                                 comment: params.key?( :comment ) ? params[:comment] : '' ).to_hash )
          end

          app.post '/api/import/pronote/decrypt' do

            json( File.open( params[:file][:tempfile] ) do |xml|
                    uai = ProNote.extract_from_xml( xml, 'UAI' )

                    halt( 401, '401 Unauthorized' ) unless user_is_profile_in_structure?( 'ADM', uai )

                    hash = Hash.from_xml( ProNote.decrypt_xml(  File.open( params[:file][:tempfile] ) ) )[:ExportEmploiDuTemps]

                    %w[ Eleves Etiquettes MotifsAbsence Absences ].each { |key| hash.delete key.to_sym }

                    File.open( params[:file][:tempfile] ) do |xmlagain|
                      hash[:DateHeureImport] = ProNote.extract_from_xml( xmlagain, 'DATEHEURE' )
                    end
                    File.open( params[:file][:tempfile] ) do |xmlagain|
                      hash[:Hash] = ProNote.extract_from_xml( xmlagain, 'VERIFICATION' )
                    end

                    hash
                  end )
          end
        end
      end
    end
  end
end
