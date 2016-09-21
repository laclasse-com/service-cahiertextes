# -*- coding: utf-8 -*-
require 'nokogiri'
require 'base64'
require 'openssl'
require 'zlib'

require_relative './data_management'
require_relative './annuaire_wrapper'
require_relative '../models/models'

# Consomme le fichier Emploi du temps exporté par Pronote
# rubocop:disable Metrics/ModuleLength
module ProNote
  module_function

  def decrypt_wrapped_data( data, rsa_key_filename )
    pk = OpenSSL::PKey::RSA.new( File.read( rsa_key_filename ) )

    pk.private_decrypt( data )
  end

  def decrypt_payload( data, aes_secret_key, aes_iv )
    aes = OpenSSL::Cipher.new 'AES-128-CBC'
    aes.decrypt
    aes.key = aes_secret_key
    aes.iv = aes_iv

    aes.update( data ) + aes.final
  end

  def inflate( string )
    zstream = Zlib::Inflate.new
    buf = zstream.inflate( string )
    zstream.finish
    zstream.close

    buf
  end

  def decrypt_xml( encrypted_xml )
    encrypted_edt_export_file = Nokogiri::XML( encrypted_xml )

    crypted_wrapped_data = Base64.decode64( encrypted_edt_export_file
                                            .search( 'PARTENAIRE' )
                                            .find do |part|
                                              part.attributes[ 'NOM' ].value == PRONOTE[:nom_integrateur]
                                            end.text )
    decrypted_wrapped_data = decrypt_wrapped_data( crypted_wrapped_data, PRONOTE[:cle_integrateur] )
    aes_secret_key = decrypted_wrapped_data[ 0..16 ]
    aes_iv = decrypted_wrapped_data[ 16..32 ]

    crypted_payload = Base64.decode64( encrypted_edt_export_file.search( 'CONTENU' ).first.text )

    decrypted_payload = decrypt_payload( crypted_payload, aes_secret_key, aes_iv )

    inflate decrypted_payload
  end

  def extract_from_xml( xml, field, _xsd = nil )
    Nokogiri::XML( xml ).search( field ).children.text
  end
end
# rubocop:enable Metrics/ModuleLength
