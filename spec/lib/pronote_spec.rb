# frozen_string_literal: true

require 'spec_helper'

describe ProNote do
    before :each do
        TableCleaner.new( DB, [] ).clean
    end

    it 'extract the UAI from the XML file' do
        uai = ProNote.extract_from_xml( File.read( 'spec/fixtures/Edt_To_LaclasseCom_0134567A.xml' ), 'UAI' )

        expect( uai ).to eq '0134567A'
    end

    it 'decrypts the XML file' do
        if ENV['TRAVIS']
            puts 'Travis doesn\'t have the private key to test this'
        else
            xml_decrypted = Nokogiri::XML( ProNote.decrypt_xml( File.read( 'spec/fixtures/Edt_To_LaclasseCom_0134567A.xml' ) ) )

            xml_clear = Nokogiri::XML( File.read( 'spec/fixtures/Edt_To_LaclasseCom_0134567A_Enclair.xml' ) )

            expect( xml_clear ).to be_equivalent_to( xml_decrypted )
        end
    end
end
