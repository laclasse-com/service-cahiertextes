# -*- coding: utf-8 -*-

require_relative '../models/models'
require_relative '../lib/pronote'
require_relative '../lib/utils/xml_to_hash'

module CahierDeTextesApp
  class ImportAPI < Grape::API
    format :json

    before do
      user_needs_to_be( %w[ DIR ] )
    end

    desc 'returns an Import record'
    params do
      requires :id, type: Integer
    end
    get '/:id' do
      Import[ params[:id] ]
    end

    desc 'returns CreneauxEmploiDuTemps related to an Import'
    params do
      requires :id, type: Integer
    end
    get '/:id/creneaux' do
      import = Import[ params[:id] ]

      # .where { ( date_creation >= import.date_import ) && ( date_creation < ( import.date_import + 10.minutes ) ) }
      CreneauEmploiDuTemps.where( etablissement_id: import.etablissement_id )
                          .where( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= DATE_FORMAT( import.date_import, '%Y-%m-%d') AND DATE_FORMAT( date_creation, '%Y-%m-%d') < '#{import.date_import + 10.minutes}'" )
                          .all
    end

    desc 'create an import record marking the execution of an import'
    params do
      requires :uai, type: String

      optional :type, type: String
      optional :comment, type: String # [[regroupements], [enseignants], [matieres], [...]]
    end
    post '/log/start' do
      etablissement = Etablissement.where(uai: params[:uai]).first

      error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

      Import.create( etablissement_id: etablissement.id,
                     date_import: Sequel::SQLTime.now,
                     type: params.key?( :type ) ? params[:type] : '',
                     comment: params.key?( :comment ) ? params[:comment] : '' )
    end

    desc 'Receive a Pronote XML file, decrypt it and send it back a JSON.'
    params do
      requires :file
    end
    post '/pronote/decrypt' do
      error!( 'Le ficher n\'est pas un fichier XML valide.', 500 ) if %r{^text/xml;.*}.match( FileMagic.new(FileMagic::MAGIC_MIME).file( params[:file][:tempfile].path ) ).nil?

      File.open( params[:file][:tempfile] ) do |xml|
        uai = ProNote.extract_from_xml( xml, 'UAI' )

        error!( '401 Unauthorized', 401 ) unless user_is_profile_in_structure?( 'DIR', uai )

        hash = Hash.from_xml( ProNote.decrypt_xml(  File.open( params[:file][:tempfile] ) ) )[:ExportEmploiDuTemps]

        %w( Eleves Etiquettes MotifsAbsence Absences ) .each { |key| hash.delete key.to_sym }

        # FIXME: fugly
        File.open( params[:file][:tempfile] ) do |xmlagain|
          hash[:DateHeureImport] = ProNote.extract_from_xml( xmlagain, 'DATEHEURE' )
        end
        File.open( params[:file][:tempfile] ) do |xmlagain|
          hash[:Hash] = ProNote.extract_from_xml( xmlagain, 'VERIFICATION' )
        end

        hash
      end
    end
  end
end
