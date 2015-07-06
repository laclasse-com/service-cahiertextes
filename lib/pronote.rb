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

  def corrige_semainiers( semainier, decalage )
    semainier = semainier.to_i if semainier.is_a? String
    semainier = semainier.to_s( 2 )
    pivot = semainier.length - decalage
    debut = semainier.slice( pivot, semainier.length )
    fin = semainier.slice( 0, pivot )

    "#{debut}#{fin}".to_i( 2 )
  end

  def extract_uai_from_xml( xml, _xsd = nil )
    Nokogiri::XML( xml ).search( 'UAI' ).children.text
  end

  def trace_rapport( rapport, key )
    LOGGER.debug "Import #{key}, #{rapport[ key ][:success].length} succès."
    LOGGER.debug "Import #{key}, #{rapport[ key ][:error].length} erreurs."
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def load_xml( xml, _xsd = nil )
    rapport = {}
    edt_clair = Nokogiri::XML( decrypt_xml( xml ) ) do |config|
      config.noblanks
    end

    etablissement = DataManagement::Accessors.create_or_get( Etablissement, UAI: edt_clair.child['UAI'] )

    annee_scolaire = edt_clair.search('AnneeScolaire').first.attributes
    etablissement.debut_annee_scolaire = annee_scolaire['DateDebut'].value
    etablissement.fin_annee_scolaire = annee_scolaire['DateFin'].value
    etablissement.date_premier_jour_premiere_semaine = annee_scolaire['DatePremierJourSemaine1'].value
    etablissement.save

    offset_semainiers = etablissement.date_premier_jour_premiere_semaine.cweek

    rapport[:plages_horaires] = { success: [], error: [] }
    edt_clair.search('PlacesParJour').children.reject { |child| child.name == 'text' }.each do |node|
      plage = DataManagement::Accessors.create_or_get( PlageHoraire, label: node['Numero'],
                                                                     debut: node['LibelleHeureDebut'],
                                                                     fin: node['LibelleHeureFin'] )

      if plage.nil?
        rapport[:plages_horaires][:error] << { label: node['Numero'],
                                               debut: node['LibelleHeureDebut'],
                                               fin: node['LibelleHeureFin'] }
      else
        rapport[:plages_horaires][:success] << plage
      end
    end
    trace_rapport( rapport, :plages_horaires )

    rapport[:salles] =  { success: [], error: [] }
    edt_clair.search('Salles').children.reject { |child| child.name == 'text' }.each do |node|
      salle = DataManagement::Accessors.create_or_get( Salle, etablissement_id: etablissement.id,
                                                              identifiant: node['Ident'],
                                                              nom: node['Nom'] )

      if salle.nil?
        rapport[:salles][:error] << { etablissement_id: etablissement.id,
                                      identifiant: node['Ident'],
                                      nom: node['Nom'] }
      else
        rapport[:salles][:success] << salle
      end
    end
    trace_rapport( rapport, :salles )

    ####
    # Les matières sont dans l'annuaire
    ####
    rapport[:matieres] = { success: [], error: [] }
    matieres = {}
    edt_clair.search('Matieres')
      .children
      .reject { |child| child.name == 'text' }
      .each do |node|
      matieres[ node['Ident'] ] = AnnuaireWrapper::Matiere.search( node['Libelle'] )['id']
      if matieres[ node['Ident'] ].nil?
        objet = { Libelle: node['Libelle'] }
        sha256 = Digest::SHA256.hexdigest( objet.to_json )

        manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
        if manually_linked_id.nil?
          FailedIdentification.create( date_creation: Time.now,
                                       sha256: sha256 )
        else
          matieres[ node['Ident'] ] = manually_linked_id.id_annuaire
        end
      end
      if matieres[ node['Ident'] ].nil?
        rapport[:matieres][:error] << { sha256: sha256,
                                        objet: objet }
      else
        rapport[:matieres][:success] << matieres[ node['Ident'] ]
      end
    end
    trace_rapport( rapport, :matieres )

    ####
    # Les enseignants sont dans l'annuaire
    ####
    rapport[:enseignants] = { success: [], error: [] }
    enseignants = {}

    edt_clair.search('Professeur')
      .each do |node|
      next if node['Nom'].nil? || node['Nom'].empty? || node['Prenom'].nil? || node['Prenom'].empty?

      user_annuaire = AnnuaireWrapper::Etablissement::User.search( etablissement.UAI, node['Nom'], node['Prenom'] )

      enseignants[ node['Ident'] ] = user_annuaire.nil? || !( user_annuaire.is_a? Array ) ? nil : user_annuaire.first['id_ent']

      if enseignants[ node['Ident'] ].nil?
        objet = { UAI: etablissement.UAI, Nom: node['Nom'], Prenom: node['Prenom'] }
        sha256 = Digest::SHA256.hexdigest( objet.to_json )

        manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
        if manually_linked_id.nil?
          FailedIdentification.create( date_creation: Time.now,
                                       sha256: sha256 )
        else
          enseignants[ node['Ident'] ] = manually_linked_id.id_annuaire
        end
      end

      if enseignants[ node['Ident'] ].nil?
        rapport[:enseignants][:error] << { sha256: sha256,
                                           objet: objet }
      else
        rapport[:enseignants][:success] << enseignants[ node['Ident'] ]
      end
    end
    trace_rapport( rapport, :enseignants )

    ####
    # Les classes, parties de classe et groupes sont dans l'annuaire
    ####
    rapport[:regroupements] = { Classe: { success: [], error: [] },
                                Groupe: { success: [], error: [] },
                                PartieDeClasse: { success: [], error: [] } }
    regroupements = { 'Classe' => {}, 'PartieDeClasse' => {}, 'Groupe' => {} }

    edt_clair.search('Classes')
      .children
      .reject { |child| child.name == 'text' }
      .each do |node|
      reponse_annuaire = AnnuaireWrapper::Etablissement::Regroupement.search( etablissement.UAI, node['Nom'] )
      code_annuaire = reponse_annuaire.nil? || !( reponse_annuaire.is_a? Array ) ? nil : reponse_annuaire.first['id']
      regroupements[ node.name ][ node['Ident'] ] = code_annuaire
      if regroupements[ node.name ][ node['Ident'] ].nil?
        objet = { UAI: etablissement.UAI, Nom: node['Nom'] }
        sha256 = Digest::SHA256.hexdigest( objet.to_json )

        manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
        if manually_linked_id.nil?
          FailedIdentification.create( date_creation: Time.now,
                                       sha256: sha256 )
        else
          regroupements[ node.name ][ node['Ident'] ] = manually_linked_id.id_annuaire
        end
      end

      if regroupements[ node.name ][ node['Ident'] ].nil?
        rapport[:regroupements][node.name.to_sym][:error] << { sha256: sha256,
                                                               objet: objet }
      else
        rapport[:regroupements][node.name.to_sym][:success] << regroupements[ node.name ][ node['Ident'] ]
      end

      next if regroupements[ 'Classe' ][ node['Ident'] ].nil?
      node.children.reject { |child| child.name == 'text' }.each do |subnode|
        if subnode['Nom'].nil?
          regroupements[ 'PartieDeClasse' ][ subnode['Ident'] ] = regroupements[ 'Classe' ][ node['Ident'] ]
        else
          reponse_annuaire = AnnuaireWrapper::Etablissement::Regroupement.search( etablissement.UAI, subnode['Nom'] )
          code_annuaire = reponse_annuaire.nil? || !( reponse_annuaire.is_a? Array ) ? nil : reponse_annuaire.first['id']
          regroupements[ subnode.name ][ subnode['Ident'] ] = code_annuaire
          if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
            objet = { UAI: etablissement.UAI, Nom: subnode['Nom'] }
            sha256 = Digest::SHA256.hexdigest( objet.to_json )

            manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
            if manually_linked_id.nil?
              FailedIdentification.create( date_creation: Time.now,
                                           sha256: sha256 )
            else
              regroupements[ subnode.name ][ subnode['Ident'] ] = manually_linked_id.id_annuaire
            end
          end
        end

        if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
          rapport[:regroupements][subnode.name.to_sym][:error] << { sha256: sha256,
                                                                    objet: objet }
        else
          rapport[:regroupements][subnode.name.to_sym][:success] << regroupements[ subnode.name ][ subnode['Ident'] ]
        end
      end
    end

    edt_clair.search('Groupes').children.reject { |child| child.name == 'text' }.each do |node|
      reponse_annuaire = AnnuaireWrapper::Etablissement::Regroupement.search( etablissement.UAI, node['Nom'] )
      code_annuaire = reponse_annuaire.nil? || !( reponse_annuaire.is_a? Array ) ? nil : reponse_annuaire.first['id']
      regroupements[ node.name ][ node['Ident'] ] = code_annuaire
      if regroupements[ node.name ][ node['Ident'] ].nil?
        objet = { UAI: etablissement.UAI, Nom: node['Nom'] }
        sha256 = Digest::SHA256.hexdigest( objet.to_json )

        manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
        if manually_linked_id.nil?
          FailedIdentification.create( date_creation: Time.now,
                                       sha256: sha256 )
        else
          regroupements[ node.name ][ node['Ident'] ] = manually_linked_id.id_annuaire
        end
      end

      if regroupements[ node.name ][ node['Ident'] ].nil?
        rapport[:regroupements][node.name.to_sym][:error] << { sha256: sha256,
                                                               objet: objet }
      else
        rapport[:regroupements][node.name.to_sym][:success] << regroupements[ node.name ][ node['Ident'] ]
      end

      next if regroupements[ node.name ][ node['Ident'] ].nil?

      node.children.each do |subnode|
        case subnode.name
        when 'PartieDeClasse'
          if subnode['Nom'].nil?
            regroupements[ 'PartieDeClasse' ][ subnode['Ident'] ] = regroupements[ 'Classe' ][ node['Ident'] ]
          else
            reponse_annuaire = AnnuaireWrapper::Etablissement::Regroupement.search( etablissement.UAI, subnode['Nom'] )
            code_annuaire = reponse_annuaire.nil? || !( reponse_annuaire.is_a? Array ) ? nil : reponse_annuaire.first['id']
            regroupements[ subnode.name ][ subnode['Ident'] ] = code_annuaire
            if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
              objet = { UAI: etablissement.UAI, Nom: subnode['Nom'] }
              sha256 = Digest::SHA256.hexdigest( objet.to_json )

              manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
              if manually_linked_id.nil? # rubocop:disable Metrics/BlockNesting
                FailedIdentification.create( date_creation: Time.now,
                                             sha256: sha256 )
              else
                regroupements[ subnode.name ][ subnode['Ident'] ] = manually_linked_id.id_annuaire
              end
            end
          end

          if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
            rapport[:regroupements][subnode.name.to_sym][:error] << { sha256: sha256,
                                                                      objet: objet }
          else
            rapport[:regroupements][subnode.name.to_sym][:success] << regroupements[ subnode.name ][ subnode['Ident'] ]
          end
        when 'Classe'
          next if subnode.name == 'text'

          reponse_annuaire = AnnuaireWrapper::Etablissement::Regroupement.search( etablissement.UAI, subnode['Nom'] )
          code_annuaire = reponse_annuaire.nil? || !( reponse_annuaire.is_a? Array ) ? nil : reponse_annuaire.first['id']
          regroupements[ subnode.name ][ subnode['Ident'] ] = code_annuaire
          if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
            objet = { UAI: etablissement.UAI, Nom: subnode['Nom'] }
            sha256 = Digest::SHA256.hexdigest( objet.to_json )

            manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
            if manually_linked_id.nil?
              FailedIdentification.create( date_creation: Time.now,
                                           sha256: sha256 )
            else
              regroupements[ subnode.name ][ subnode['Ident'] ] = manually_linked_id.id_annuaire
            end
          end

          if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
            rapport[:regroupements][subnode.name.to_sym][:error] << { sha256: sha256,
                                                                      objet: objet }
          else
            rapport[:regroupements][subnode.name.to_sym][:success] << regroupements[ subnode.name ][ subnode['Ident'] ]
          end
        end
      end
    end

    rapport[:creneaux] = { matieres: { success: [], error: [] },
                           enseignants: { success: [], error: [] },
                           regroupements: { success: [], error: [] },
                           salles: { success: [], error: [] } }
    edt_clair.search('Cours/Cours')
      .reject { |child| child.name == 'text' }
      .each do |node|
      debut = PlageHoraire[ label: node['NumeroPlaceDebut'] ][:id]
      fin = PlageHoraire[ label: node['NumeroPlaceDebut'].to_i + node['NombrePlaces'].to_i - 1 ][:id]
      matiere_id = nil

      node.children.reject { |child| child.name == 'text' }.each do |subnode|  # FIXME: peut sûrement mieux faire
        matiere_id = matieres[ subnode['Ident'] ] if subnode.name == 'Matiere'
        if matiere_id.nil?
          rapport[:creneaux][:matieres][:error] << subnode['Ident']
        else
          rapport[:creneaux][:matieres][:success] << matiere_id
        end
      end
      next if matiere_id.nil?
      creneau = DataManagement::Accessors
                .create_or_get( CreneauEmploiDuTemps,
                                jour_de_la_semaine: node['Jour'], # 1: 'lundi' .. 7: 'dimanche', norme ISO-8601
                                debut: debut,
                                fin: fin,
                                matiere_id: matiere_id )

      node.children.each do |subnode|
        case subnode.name
        when 'Professeur'
          if enseignants[ subnode['Ident'] ].nil?
            rapport[:creneaux][:enseignants][:error] << subnode['Ident']
          else
            rapport[:creneaux][:enseignants][:success] << enseignants[ subnode['Ident'] ]
            if creneau.enseignants.count { |ce| ce[:enseignant_id] == enseignants[ subnode['Ident'] ] } == 0
              CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
              creneau.add_enseignant(enseignant_id: enseignants[ subnode['Ident'] ],
                                     semaines_de_presence: corrige_semainiers( subnode['Semaines'], offset_semainiers ) )
              CreneauEmploiDuTempsEnseignant.restrict_primary_key
            end
          end
        when 'Classe', 'PartieDeClasse', 'Groupe' # on ne distingue pas les 3 types de regroupements
          if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
            rapport[:creneaux][:regroupements][:error] << "#{subnode['Ident']} (#{subnode.name})"
          else
            rapport[:creneaux][:regroupements][:success] << regroupements[ subnode.name ][ subnode['Ident'] ]
            if creneau.regroupements.count do |cr|
                 cr[:regroupement_id] == "#{regroupements[ subnode.name ][ subnode['Ident'] ]}"
               end == 0
              CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
              creneau.add_regroupement(regroupement_id: regroupements[ subnode.name ][ subnode['Ident'] ],
                                       semaines_de_presence: corrige_semainiers( subnode['Semaines'], offset_semainiers ) )
              CreneauEmploiDuTempsRegroupement.restrict_primary_key
            end
          end
        when 'Salle'
          unless creneau.salles.include?( Salle[ identifiant: subnode['Ident'] ] )
            creneau.add_salle( Salle[ identifiant: subnode['Ident'] ] )
          end
          cs = CreneauEmploiDuTempsSalle
               .where( salle_id: Salle[ identifiant: subnode['Ident'] ][:id] )
               .where( creneau_emploi_du_temps_id: creneau.id )
          cs.update(semaines_de_presence: corrige_semainiers( subnode['Semaines'], offset_semainiers ) )
          # cs.save
        end
      end
    end

    CreneauEmploiDuTempsRegroupement
      .select(:regroupement_id)
      .map(&:regroupement_id)
      .uniq
      .reject { |id| id == 'undefined' }
      .each do |regroupement_id|
      DataManagement::Accessors.create_or_get( CahierDeTextes, regroupement_id: regroupement_id )
    end

    rapport
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/ModuleLength
