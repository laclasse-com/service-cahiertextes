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

  def load_etablissement( xml )
    etablissement = DataManagement::Accessors.create_or_get( Etablissement, UAI: xml.child['UAI'] )

    annee_scolaire = xml.search('AnneeScolaire').first.attributes
    etablissement.debut_annee_scolaire = annee_scolaire['DateDebut'].value
    etablissement.fin_annee_scolaire = annee_scolaire['DateFin'].value
    etablissement.date_premier_jour_premiere_semaine = annee_scolaire['DatePremierJourSemaine1'].value
    etablissement.save

    etablissement
  end

  def load_plages_horaires( xml )
    rapport = { success: [], error: [] }
    xml.search('PlacesParJour').children.each do |node|
      next if node.name == 'text'
      plage = DataManagement::Accessors.create_or_get( PlageHoraire, label: node['Numero'],
                                                                     debut: node['LibelleHeureDebut'],
                                                                     fin: node['LibelleHeureFin'] )

      if plage.nil?
        rapport[:error] << { label: node['Numero'],
                             debut: node['LibelleHeureDebut'],
                             fin: node['LibelleHeureFin'] }
      else
        rapport[:success] << plage
      end
    end

    rapport
  end

  def load_salles( xml, etablissement )
    rapport = { success: [], error: [] }

    xml.search('Salles').children.reject { |child| child.name == 'text' }.each do |node|
      salle = DataManagement::Accessors.create_or_get( Salle, etablissement_id: etablissement.id,
                                                              identifiant: node['Ident'],
                                                              nom: node['Nom'] )

      if salle.nil?
        rapport[:error] << { etablissement_id: etablissement.id,
                             identifiant: node['Ident'],
                             nom: node['Nom'] }
      else
        rapport[:success] << salle
      end
    end

    rapport
  end

  def load_matieres( xml )
    rapport = { success: [], error: [] }
    matieres = {}

    xml.search('Matieres')
      .children
      .each do |node|
      next if node.name == 'text'

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

        rapport[:error] << { sha256: sha256, objet: objet } if matieres[ node['Ident'] ].nil?
      end

      rapport[:success] << { id: matieres[ node['Ident'] ], libelle: node['Libelle'] } unless matieres[ node['Ident'] ].nil?
    end

    [ rapport, matieres ]
  end

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def load_enseignants( xml, etablissement )
    rapport = { success: [], error: [] }
    enseignants = {}

    xml.search('Professeur')
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
        rapport[:error] << { sha256: sha256, objet: objet } if enseignants[ node['Ident'] ].nil?
      end

      rapport[:success] << { id: enseignants[ node['Ident'] ], nom: node['Nom'], prenom: node['Prenom'] } unless enseignants[ node['Ident'] ].nil?
    end

    [ rapport, enseignants ]
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def load_regroupements( xml, etablissement )
    rapport = { Classe: { success: [], error: [] },
                Groupe: { success: [], error: [] },
                PartieDeClasse: { success: [], error: [] } }
    regroupements = { 'Classe' => {}, 'PartieDeClasse' => {}, 'Groupe' => {} }

    xml.search('Classes')
      .children
      .each do |node|
      next if node.name == 'text'

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

        rapport[node.name.to_sym][:error] << { sha256: sha256, objet: objet } if regroupements[ node.name ][ node['Ident'] ].nil?
      end

      rapport[node.name.to_sym][:success] << { id: regroupements[ node.name ][ node['Ident'] ], nom: node['Nom'] } unless regroupements[ node.name ][ node['Ident'] ].nil?

      next if regroupements[ 'Classe' ][ node['Ident'] ].nil?

      node.children.each do |subnode|
        next if subnode.name == 'text'

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

            rapport[node.name.to_sym][:error] << { sha256: sha256, objet: objet } if regroupements[ node.name ][ node['Ident'] ].nil?
          end
        end

        rapport[subnode.name.to_sym][:success] << { id: regroupements[ subnode.name ][ subnode['Ident'] ], nom: subnode['Nom'] } unless regroupements[ subnode.name ][ subnode['Ident'] ].nil?
      end
    end

    xml.search('Groupes').children.each do |node|
      next if node.name == 'text'

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

        rapport[node.name.to_sym][:error] << { sha256: sha256, objet: objet } if regroupements[ node.name ][ node['Ident'] ].nil?
      end
      rapport[node.name.to_sym][:success] << { id: regroupements[ node.name ][ node['Ident'] ], nom: node['Nom'] } unless regroupements[ node.name ][ node['Ident'] ].nil?

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

            rapport[subnode.name.to_sym][:error] << { sha256: sha256, objet: objet } if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
          end

          rapport[subnode.name.to_sym][:success] << { id: regroupements[ subnode.name ][ subnode['Ident'] ], nom: subnode['Nom'] } unless regroupements[ subnode.name ][ subnode['Ident'] ].nil?
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

            rapport[subnode.name.to_sym][:error] << { sha256: sha256, objet: objet } if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
          end

          rapport[subnode.name.to_sym][:success] << { id: regroupements[ subnode.name ][ subnode['Ident'] ], nom: subnode['Nom'] } unless regroupements[ subnode.name ][ subnode['Ident'] ].nil?
        end
      end
    end

    [ rapport, regroupements ]
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def load_creneaux( xml, etablissement, matieres, enseignants, regroupements )
    rapport = { matieres: { success: [], error: [] },
                enseignants: { success: [], error: [] },
                regroupements: { success: [], error: [] },
                salles: { success: [], error: [] } }

    offset_semainiers = etablissement.date_premier_jour_premiere_semaine.cweek

    xml.search('Cours/Cours')
       .each do |node|
      next if node.name == 'text'

      debut = PlageHoraire[ label: node['NumeroPlaceDebut'] ][:id]
      fin = PlageHoraire[ label: node['NumeroPlaceDebut'].to_i + node['NombrePlaces'].to_i - 1 ][:id]
      matiere_id = matieres[ node.search( 'Matiere' ).first.attributes['Ident'].value ]

      next if matiere_id.nil?

      creneau = DataManagement::Accessors
                .create_or_get( CreneauEmploiDuTemps,
                                jour_de_la_semaine: node['Jour'], # 1: 'lundi' .. 7: 'dimanche', norme ISO-8601
                                debut: debut,
                                fin: fin,
                                matiere_id: matiere_id )

      LOGGER.debug " . Created Créneau #{CreneauEmploiDuTemps.count} #{creneau.id} (#{matiere_id} ; #{debut} ; #{fin})"

      node.children.each do |subnode|
        case subnode.name
        when 'Professeur'
          if enseignants[ subnode['Ident'] ].nil?
            rapport[:enseignants][:error] << subnode['Ident']
          else
            rapport[:enseignants][:success] << enseignants[ subnode['Ident'] ]
            if creneau.enseignants.count { |ce| ce[:enseignant_id] == enseignants[ subnode['Ident'] ] } == 0
              CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
              creneau.add_enseignant(enseignant_id: enseignants[ subnode['Ident'] ],
                                     semaines_de_presence: corrige_semainiers( subnode['Semaines'], offset_semainiers ) )
              CreneauEmploiDuTempsEnseignant.restrict_primary_key

              LOGGER.debug "  -> added enseignant #{enseignants[ subnode['Ident'] ]}"
            end
          end

        when 'Classe', 'PartieDeClasse', 'Groupe' # on ne distingue pas les 3 types de regroupements
          if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
            rapport[:regroupements][:error] << "#{subnode['Ident']} (#{subnode.name})"
          else
            rapport[:regroupements][:success] << regroupements[ subnode.name ][ subnode['Ident'] ]
            if creneau.regroupements.count do |cr|
                 cr[:regroupement_id] == "#{regroupements[ subnode.name ][ subnode['Ident'] ]}"
               end == 0
              CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
              creneau.add_regroupement(regroupement_id: regroupements[ subnode.name ][ subnode['Ident'] ],
                                       semaines_de_presence: corrige_semainiers( subnode['Semaines'], offset_semainiers ) )
              CreneauEmploiDuTempsRegroupement.restrict_primary_key

              LOGGER.debug "  -> added regroupement #{regroupements[ subnode['Ident'] ]}"
            end
          end

        when 'Salle'
          unless creneau.salles.include?( Salle[ identifiant: subnode['Ident'] ] )
            creneau.add_salle( Salle[ identifiant: subnode['Ident'] ] )

            LOGGER.debug "  -> added salle #{Salle[ identifiant: subnode['Ident'] ]}"
          end
          cs = CreneauEmploiDuTempsSalle
               .where( salle_id: Salle[ identifiant: subnode['Ident'] ][:id] )
               .where( creneau_emploi_du_temps_id: creneau.id )
          cs.update(semaines_de_presence: corrige_semainiers( subnode['Semaines'], offset_semainiers ) )
        end
      end
    end

    rapport
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def provision_cahiers_de_textes
    CreneauEmploiDuTempsRegroupement
      .select(:regroupement_id)
      .map(&:regroupement_id)
      .uniq
      .reject { |id| id == 'undefined' }
      .each do |regroupement_id|
      DataManagement::Accessors.create_or_get( CahierDeTextes, regroupement_id: regroupement_id )
    end
  end

  def load_xml( xml, _xsd = nil )
    rapport = {}
    edt_clair = Nokogiri::XML( decrypt_xml( xml ) ) do |config|
      config.noblanks
    end

    etablissement = load_etablissement( edt_clair )

    rapport[:plages_horaires] = load_plages_horaires( edt_clair )
    trace_rapport( rapport, :plages_horaires )

    rapport[:salles] = load_salles( edt_clair, etablissement )
    trace_rapport( rapport, :salles )

    ####
    # Les matières sont dans l'annuaire
    ####
    rapport[:matieres], matieres = load_matieres( edt_clair )
    trace_rapport( rapport, :matieres )

    ####
    # Les enseignants sont dans l'annuaire
    ####
    rapport[:enseignants], enseignants = load_enseignants( edt_clair, etablissement )
    trace_rapport( rapport, :enseignants )

    ####
    # Les classes, parties de classe et groupes sont dans l'annuaire
    ####
    rapport[:regroupements], regroupements = load_regroupements( edt_clair, etablissement )
    rapport[:regroupements].keys.each do |key|
      trace_rapport( rapport[:regroupements], key )
    end

    rapport[:creneaux] = load_creneaux( edt_clair, etablissement, matieres, enseignants, regroupements )
    rapport[:creneaux].keys.each do |key|
      trace_rapport( rapport[:creneaux], key )
    end

    provision_cahiers_de_textes

    rapport
  end
end
# rubocop:enable Metrics/ModuleLength
