#-*- coding: utf-8 -*-

require 'spec_helper'

describe ProNote do
  before :each do
    TableCleaner.new( DB, [] ).clean
  end

  it 'extract the UAI from the XML file' do
    uai = ProNote.extract_uai_from_xml( File.read( 'spec/fixtures/Edt_To_LaclasseCom_0134567A.xml' ) )

    expect( uai ).to eq '0134567A'
  end

  it 'decrypts the XML file' do
    if ENV['TRAVIS']
      LOGGER.debug 'Travis doesn\'t have the private key to test this'
    else
      xml_decrypted = Nokogiri::XML( ProNote.decrypt_xml( File.read( 'spec/fixtures/Edt_To_LaclasseCom_0134567A.xml' ) ) )

      xml_clear = Nokogiri::XML( File.read( 'spec/fixtures/Edt_To_LaclasseCom_0134567A_Enclair.xml' ) )

      expect( xml_clear ).to be_equivalent_to( xml_decrypted )
    end
  end

  it 'decrypts and load the whole file, one pass, annuaire finds nothing' do
    if ENV['TRAVIS']
      LOGGER.debug 'Travis doesn\'t have the private key to test this'
    else
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

      rapport = ProNote.load_xml( File.read( 'spec/fixtures/Edt_To_LaclasseCom_0134567A.xml' ) )

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

  it 'decrypts and load the whole file, one pass, annuaire finds everything' do
    if ENV['TRAVIS']
      LOGGER.debug 'Travis doesn\'t have the private key to test this'
    else
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

      rapport = ProNote.load_xml( File.read( 'spec/fixtures/Edt_To_LaclasseCom_0134567A.xml' ) )

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
end
