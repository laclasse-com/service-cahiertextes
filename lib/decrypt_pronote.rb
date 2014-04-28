require 'nokogiri'
require 'base64'
require 'openssl'
require 'zipruby'

def decrypt_xml(encrypted_xml, xsd = nil)
  encrypted_xml = Nokogiri::XML(encrypted_xml)

  #fail 'fichier XML invalide' unless !xsd.nil? && Nokogiri::XML::Schema( xsd ).valid?( encrypted_xml )

  xml = encrypted_xml.at 'EXPORT_INDEX_EDUCATION'

  hxml = {  version: xml.at('VERSION').child.text,
            logiciel: xml.at('LOGICIEL').child.text,
            cles_chiffrees: xml.at('CLES').child.text,
            contenu_chiffre: xml.at('CONTENU').child.text,
            verification: xml.at('VERIFICATION').child.text,
            dateheure: xml.at('DATEHEURE').child.text,
            uai: xml.at('UAI').child.text,
            nometablissement: xml.at('NOMETABLISSEMENT').child.text,
            codepostalville: xml.at('CODEPOSTALVILLE').child.text }

  hxml[:contenu_chiffre_debased64] = Base64.decode64 hxml[:contenu_chiffre]
  hxml[:cles_chiffrees_debased64] = Base64.decode64 hxml[:cles_chiffrees]

  pk = OpenSSL::PKey::RSA.new File.read '../clef_privee'
  STDERR.puts 'WE HAZ PRIVATE KEY!' if pk.private?
  STDERR.puts 'WE HAZ PUBLIC KEY!' if pk.public?

  # FIXME: OpenSSL::PKey::RSAError: padding check failed
  hxml[:cles_AES] = pk.private_decrypt hxml[:cles_chiffrees_debased64]

  # FIXME: liste des types dans OpenSSL::Cipher.ciphers
  aes = OpenSSL::Cipher.new 'AES-128-CBC'
  aes.decrypt
  aes.key = hxml[:cles_AES]
  hxml[:contenu_zippe] = aes.update( hxml[:contenu_chiffre_debased64] ) + aes.final

  hxml[:contenu] = Zip::Archive.open_buffer( hxml[:contenu_zippe] ) { |archive|
    archive.each { |entry|
      entry.name
      entry.read
    }
  }
end

decrypt_xml File.open '../spec/fixtures/Edt_To_LaclasseCom_0134567A.xml'
