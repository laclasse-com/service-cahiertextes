#-*- coding: utf-8 -*-

require 'spec_helper'

require_relative '../helper_mocks/pronote_xml'

describe ProNote do
  before :each do
    TableCleaner.new( DB, [] ).clean
  end

  it 'extract the UAI from the XML file' do
    uai = ProNote.extract_uai_from_xml( PRONOTE_ENCRYPTED_XML )

    expect( uai ).to eq '0134567A'
  end

  it 'decrypts the XML file' do
    xml_decrypted = Nokogiri::XML( ProNote.decrypt_xml( PRONOTE_ENCRYPTED_XML ) )

    xml_clear = Nokogiri::XML( PRONOTE_CLEAR_XML )

    expect( xml_clear ).to be_equivalent_to( xml_decrypted )
  end

  it 'decrypts and load the whole file, one pass, annuaire finds nothing' do
    module AnnuaireWrapper
      module Matiere
        module_function

        def search( _label )
          { 'id' => nil }
        end
      end

      module Etablissement
        module User
          module_function

          def search( _uai, _nom, _prenom )
            nil
          end
        end
        module Regroupement
          module_function

          def search( _uai, _nom )
            nil
          end
        end
      end
    end

    rapport = ProNote.load_xml( PRONOTE_ENCRYPTED_XML )

    expect( rapport[:plages_horaires][:success].count ).to eq 20
    expect( PlageHoraire.count ).to eq 20
    expect( rapport[:salles][:success].count ).to eq 24
    expect( Salle.count ).to eq 24
    expect( rapport[:matieres][:error].count ).to eq 25
    expect( rapport[:enseignants][:error].count ).to eq 31
    expect( CreneauEmploiDuTemps.count ).to eq 0
    expect( FailedIdentification.count ).to eq 120
  end

  it 'decrypts and load the whole file, one pass, annuaire finds everything' do
    module AnnuaireWrapper
      module Matiere
        module_function

        def search( label )
          { 'id' => label }
        end
      end

      module Etablissement
        module User
          module_function

          def search( uai, nom, prenom )
            [ { 'id_ent' => "#{uai}#{nom}#{prenom}" } ]
          end
        end
        module Regroupement
          module_function

          def search( uai, nom )
            [ { 'id' => "#{uai}#{nom}" } ]
          end
        end
      end
    end

    rapport = ProNote.load_xml( PRONOTE_ENCRYPTED_XML )

    File.open( '/tmp/rapport.import.json', 'w' ) { |f| f.write rapport }

    expect( rapport[:plages_horaires][:success].count ).to eq 20
    expect( PlageHoraire.count ).to eq 20
    expect( rapport[:salles][:success].count ).to eq 24
    expect( Salle.count ).to eq 24
    expect( rapport[:matieres][:error].count ).to eq 25
    expect( rapport[:enseignants][:error].count ).to eq 31
    expect( CreneauEmploiDuTemps.count ).to eq 0
    expect( FailedIdentification.count ).to eq 120
  end
end
