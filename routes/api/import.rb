# coding: utf-8
require_relative '../../lib/pronote'
require_relative '../../lib/xml_to_hash'
require_relative '../../models/import'

module Routes
    module Api
        module ImportAPI
            def self.registered( app )
                app.get '/api/import/:id/?' do
                    # {
                    param :id, Integer, required: true
                    # }

                    json( Import[ params['id'] ] )
                end

                app.get '/api/import/:id/timeslots/?' do
                    # {
                    param :id, Integer, required: true
                    # }

                    import = Import[ params['id'] ]

                    json( Timeslot.where( structure_id: import.structure_id )
                                  .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= DATE_FORMAT( import.ctime, '%Y-%m-%d') AND DATE_FORMAT( ctime, '%Y-%m-%d') < '#{import.ctime + 10.minutes}'" ) )
                                  .all )
                end

                app.post '/api/import/log/start/?' do
                    # {
                    param :structure_id, String, required: true
                    param :type, String, required: false
                    param :comment, String, required: false
                    # }

                    json( Import.create( structure_id: params['structure_id'],
                                         ctime: Sequel::SQLTime.now,
                                         type: params.key?( :type ) ? params[:type] : '',
                                         comment: params.key?( :comment ) ? params[:comment] : '' ).to_hash )
                end

                app.post '/api/import/pronote/decrypt' do
                    # {
                    # param :file, required: true
                    # }

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
