# coding: utf-8
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

          app.get '/api/import/:id/timeslots/?' do
            import = Import[ params[:id] ]

            json( Timeslot.where( structure_id: import.structure_id )
                                      .where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= DATE_FORMAT( import.date_import, '%Y-%m-%d') AND DATE_FORMAT( ctime, '%Y-%m-%d') < '#{import.date_import + 10.minutes}'" ) )
                                      .all )
          end

          app.post '/api/import/log/start/?' do
            etablissement = Structure.where(uai: params[:uai]).first

            halt( 404, "Établissement #{params[:uai]} inconnu" ) if structure.nil?

            json( Import.create( structure_id: structure.id,
                                 date_import: Sequel::SQLTime.now,
                                 type: params.key?( :type ) ? params[:type] : '',
                                 comment: params.key?( :comment ) ? params[:comment] : '' ).to_hash )
          end

          app.post '/api/import/pronote/decrypt' do
            halt( 500, 'Le fichier n\'est pas un fichier XML valide.' ) if %r{^(application|text)/xml;.*}.match( FileMagic.new(FileMagic::MAGIC_MIME).file( params[:file][:tempfile].path ) ).nil?

            json( File.open( params[:file][:tempfile] ) do |xml|
                    nxml = Nokogiri::XML( xml )

                    crypted = !nxml.search( 'CLES' ).empty?

                    if crypted
                      uai = nxml.search( 'UAI' ).children.text

                      halt( 401, '401 Unauthorized' ) unless user_is_profile_in_structure?( 'ADM', uai )

                      hash = Hash.from_xml( ProNote.decrypt_xml( File.open( params[:file][:tempfile] ) ) )[:ExportEmploiDuTemps]
                    else
                      hash = Hash.from_xml( File.open( params[:file][:tempfile] ) )[:ExportEmploiDuTemps]
                    end

                    %w[ Eleves Etiquettes MotifsAbsence Absences Professeurs Personnels Materiels Nomenclatures Responsables ].each do |key|
                      hash.delete( key.to_sym )
                    end

                    hash
                  end )
          end
        end
      end
    end
  end
end
