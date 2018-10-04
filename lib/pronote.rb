# frozen_string_literal: true

require 'nokogiri'
require 'base64'
require 'openssl'
require 'zlib'

# Consomme le fichier Emploi du temps exporté par Pronote
module ProNote
    module_function

    def decrypt_wrapped_data( data, rsa_key_filename )
        OpenSSL::PKey::RSA.new( File.read( rsa_key_filename ) ).private_decrypt( data )
    end

    def decrypt_payload( data, aes_secret_key, aes_iv )
        aes = OpenSSL::Cipher.new( 'AES-128-CBC' )
        aes.decrypt

        aes.key = aes_secret_key[0..15]
        aes.iv = aes_iv[0..15]

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

        crypted_wrapped_data = Base64.decode64( encrypted_edt_export_file.search( 'PARTENAIRE' )
                                                                         .find { |part| part.attributes['NOM'].value == PRONOTE[:nom_integrateur] }
                                                                         .text )

        decrypted_wrapped_data = decrypt_wrapped_data( crypted_wrapped_data, PRONOTE[:cle_integrateur] )

        aes_secret_key = decrypted_wrapped_data[0..16]
        aes_iv = decrypted_wrapped_data[16..32]

        crypted_payload = Base64.decode64( encrypted_edt_export_file.search( 'CONTENU' ).first.text )

        decrypted_payload = decrypt_payload( crypted_payload, aes_secret_key, aes_iv )

        inflate( decrypted_payload )
    end
end
