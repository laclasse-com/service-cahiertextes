# frozen_string_literal: true

require_relative '../../lib/pronote'
require_relative '../../lib/xml_to_hash'
require_relative '../../models/import'

module Routes
    module Api
        module ImportAPI
            def self.registered( app )
                app.post '/api/import/log/start/?' do
                    # {
                    param 'structure_id', String, required: true
                    param 'type', String, required: true
                    # }

                    halt( 401, '401 Unauthorized' ) unless user_is_x_in_structure_s?( %w[ADM], params['structure_id'] )

                    json( Import.create( structure_id: params['structure_id'],
                                         ctime: DateTime.now,
                                         import_type_id: params.key?( 'type' ) ? ImportType[label: params['type']]&.id : '',
                                         author_id: user['id'] ) )
                end

                app.post '/api/import/pronote/decrypt' do
                    # {
                    # param 'file', required: true
                    # }

                    # halt( 500, 'Le fichier n\'est pas un fichier XML valide.' ) if %r{^(application|text)/xml;.*}.match( FileMagic.new(FileMagic::MAGIC_MIME).file( params['file']['tempfile'].path ) ).nil?

                    json( File.open( params['file']['tempfile'] ) do |xml|
                              nxml = Nokogiri::XML( xml )

                              halt( 401, '401 Unauthorized' ) unless user_is_x_in_structure_s?( %w[ADM], nxml.search( 'UAI' ).children.text )

                              crypted = !nxml.search( 'CLES' ).empty?

                              if crypted
                                  uai = nxml.search( 'UAI' ).children.text

                                  halt( 401, '401 Unauthorized' ) unless user_is_profile_in_structure?( 'ADM', uai )

                                  hash = Hash.from_xml( ProNote.decrypt_xml( File.open( params['file']['tempfile'] ) ) )[:ExportEmploiDuTemps]
                              else
                                  hash = Hash.from_xml( File.open( params['file']['tempfile'] ) )[:ExportEmploiDuTemps]
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
