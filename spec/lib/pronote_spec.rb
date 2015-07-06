#-*- coding: utf-8 -*-

require 'spec_helper'

describe ProNote do
  before :all do
    TableCleaner.new( DB, [] ).clean
  end

  it 'is still to be done' do
    STDERR.puts 'FIXME'
    expect( 1 ).to eq 1
  end

  it 'extract the UAI from the XML file' do
    uai = ProNote.extract_uai_from_xml( File.read( './spec/fixtures/Edt_To_LaclasseCom_0134567A.xml' ) )

    expect( uai ).to eq '0134567A'
  end

  it 'decrypts the XML file' do
    xml_decrypted = Nokogiri::XML( ProNote.decrypt_xml( File.read( './spec/fixtures/Edt_To_LaclasseCom_0134567A.xml' ) ) )

    xml_clear = Nokogiri::XML( File.read( './spec/fixtures/Edt_To_LaclasseCom_0134567A_Enclair.xml' ) )

    expect( xml_clear ).to be_equivalent_to( xml_decrypted )
  end

  it 'decrypts and load the whole file, first pass' do
    rapport = ProNote.load_xml( File.read( './spec/fixtures/Edt_To_LaclasseCom_0134567A.xml' ) )

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
