# frozen_string_literal: true

# require 'spec_helper'

require_relative '../../config/options'
require_relative '../../lib/pronote'

require 'rspec/matchers' # required by equivalent-xml custom matcher `be_equivalent_to`
require 'equivalent-xml'

describe ProNote do
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
