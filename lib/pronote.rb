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

  ####################
  # OLD IMPORT BELOW #
  ####################
  def pad_semainier( semainier )
    (52 - semainier.length).times { semainier += '0' }

    semainier
  end

  # FIXME: might be wrong ?!
  def corrige_semainiers( semainier, decalage )
    semainier = semainier.to_i if semainier.is_a? String
    semainier = pad_semainier( semainier.to_s( 2 ) )

    pivot_point = 52 - decalage

    debut = semainier.slice( pivot_point, semainier.length )
    fin = semainier.slice( 0, pivot_point )

    fixed_semainier = "#{debut}#{fin}"

    fixed_semainier.to_i( 2 )
  end

  def extract_uai_from_xml( xml, _xsd = nil )
    Nokogiri::XML( xml ).search( 'UAI' ).children.text
  end

  def trace_rapport( _rapport, _key )
    # LOGGER.info "Import #{key}, #{rapport[ key ][:success].length} succès."
    # LOGGER.info "Import #{key}, #{rapport[ key ][:error].length} erreurs."
  end

  def load_etablissement( xml, stage )
    etablissement = DataManagement::Accessors.create_or_get( Etablissement, UAI: xml.child['UAI'] )

    annee_scolaire = xml.search('AnneeScolaire').first.attributes
    etablissement.debut_annee_scolaire = annee_scolaire['DateDebut'].value
    etablissement.fin_annee_scolaire = annee_scolaire['DateFin'].value
    etablissement.date_premier_jour_premiere_semaine = annee_scolaire['DatePremierJourSemaine1'].value

    etablissement.add_import( date_import: Time.now,
                              type: 'pronote',
                              stage: stage )
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
      salle = DataManagement::Accessors.create_or_get( Salle,
                                                       etablissement_id: etablissement.id,
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

  def load_matieres( xml, etablissement )
    rapport = { success: [], error: [] }
    matieres = {}

    xml.search('Matieres').children.each do |node|
      next if node.name == 'text'

      matieres[ node['Ident'] ] = AnnuaireWrapper::Matiere.search( node['Libelle'] )['id']
      if matieres[ node['Ident'] ].nil?
        objet = { Libelle: node['Libelle'] }
        sha256 = Digest::SHA256.hexdigest( objet.to_json )

        manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
        if manually_linked_id.nil?
          FailedIdentification.create( import_id: etablissement.imports.last.id,
                                       date_creation: Time.now,
                                       sha256: sha256 )
        else
          matieres[ node['Ident'] ] = manually_linked_id.id_annuaire
        end

        rapport[:error] << { sha256: sha256, objet: objet } if matieres[ node['Ident'] ].nil?
      end

      rapport[:success] << { id: matieres[ node['Ident'] ], libelle: node['Libelle'] } unless matieres[ node['Ident'] ].nil?
    end

    [ matieres, rapport ]
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

      enseignants[ node['Ident'] ] = { id: user_annuaire.nil? || !( user_annuaire.is_a? Array ) ? nil : user_annuaire.first['id_ent'] }

      if enseignants[ node['Ident'] ][:id].nil?
        objet = { UAI: etablissement.UAI, Nom: node['Nom'], Prenom: node['Prenom'] }
        sha256 = Digest::SHA256.hexdigest( objet.to_json )

        manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
        if manually_linked_id.nil?
          FailedIdentification.create( import_id: etablissement.imports.last.id,
                                       date_creation: Time.now,
                                       sha256: sha256 )
        else
          enseignants[ node['Ident'] ] = { id: manually_linked_id.id_annuaire }
        end
        if enseignants[ node['Ident'] ][:id].nil?
          rapport[:error] << { sha256: sha256, objet: objet }
          next
        end
      end

      user_detailed = AnnuaireWrapper::User.get( enseignants[ node['Ident'] ][:id] )
      enseignants[ node['Ident'] ][:regroupements] = user_detailed['classes']
                                                     .concat( user_detailed['groupes_eleves'] )
                                                     .concat( user_detailed['groupes_libres'] )
                                                     .select { |regroupement| regroupement['etablissement_code'] == etablissement.UAI }
                                                     .map { |regroupement| regroupement.key?( 'classe_id' ) ? regroupement['classe_id'] : regroupement['groupe_id'] }
                                                     .compact

      rapport[:success] << { id: enseignants[ node['Ident'] ][:id], nom: node['Nom'], prenom: node['Prenom'] }
    end

    [ enseignants, rapport ]
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

    xml
      .search('Classes')
      .children
      .each do |node|
      next unless %w(PartieDeClasse Classe Groupe).include? node.name

      reponse_annuaire = AnnuaireWrapper::Etablissement::Regroupement.search( etablissement.UAI, node['Nom'] )
      code_annuaire = reponse_annuaire.nil? || !( reponse_annuaire.is_a? Array ) ? nil : reponse_annuaire.first['id']
      regroupements[ node.name ][ node['Ident'] ] = code_annuaire
      if regroupements[ node.name ][ node['Ident'] ].nil?
        objet = { UAI: etablissement.UAI, Nom: node['Nom'] }
        sha256 = Digest::SHA256.hexdigest( objet.to_json )

        manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
        if manually_linked_id.nil?
          FailedIdentification.create( import_id: etablissement.imports.last.id,
                                       date_creation: Time.now,
                                       sha256: sha256 )
        else
          regroupements[ node.name ][ node['Ident'] ] = manually_linked_id.id_annuaire
        end

        rapport[node.name.to_sym][:error] << { sha256: sha256, objet: objet } if regroupements[ node.name ][ node['Ident'] ].nil?
      end

      rapport[node.name.to_sym][:success] << { id: regroupements[ node.name ][ node['Ident'] ], nom: node['Nom'] } unless regroupements[ node.name ][ node['Ident'] ].nil?

      next if regroupements[ 'Classe' ][ node['Ident'] ].nil?

      node.children.each do |subnode|
        next unless %w(PartieDeClasse Classe Groupe).include? subnode.name

        if !subnode.key?( 'Nom') || subnode['Nom'].nil?
          regroupements[ subnode.name ][ subnode['Ident'] ] = regroupements[ 'Classe' ][ node['Ident'] ]
        else
          reponse_annuaire = AnnuaireWrapper::Etablissement::Regroupement.search( etablissement.UAI, subnode['Nom'] )
          code_annuaire = reponse_annuaire.nil? || !( reponse_annuaire.is_a? Array ) ? nil : reponse_annuaire.first['id']
          regroupements[ subnode.name ][ subnode['Ident'] ] = code_annuaire
          if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
            objet = { UAI: etablissement.UAI, Nom: subnode['Nom'] }
            sha256 = Digest::SHA256.hexdigest( objet.to_json )
            manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
            if manually_linked_id.nil?
              FailedIdentification.create( import_id: etablissement.imports.last.id,
                                           date_creation: Time.now,
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
      next unless %w(Groupe).include? node.name

      reponse_annuaire = AnnuaireWrapper::Etablissement::Regroupement.search( etablissement.UAI, node['Nom'] )
      code_annuaire = reponse_annuaire.nil? || !( reponse_annuaire.is_a? Array ) ? nil : reponse_annuaire.first['id']
      regroupements[ node.name ][ node['Ident'] ] = code_annuaire
      if regroupements[ node.name ][ node['Ident'] ].nil?
        objet = { UAI: etablissement.UAI, Nom: node['Nom'] }
        sha256 = Digest::SHA256.hexdigest( objet.to_json )

        manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
        if manually_linked_id.nil?
          FailedIdentification.create( import_id: etablissement.imports.last.id,
                                       date_creation: Time.now,
                                       sha256: sha256 )
        else
          regroupements[ node.name ][ node['Ident'] ] = manually_linked_id.id_annuaire
        end

        rapport[node.name.to_sym][:error] << { sha256: sha256, objet: objet } if regroupements[ node.name ][ node['Ident'] ].nil?
      end
      rapport[node.name.to_sym][:success] << { id: regroupements[ node.name ][ node['Ident'] ], nom: node['Nom'] } unless regroupements[ node.name ][ node['Ident'] ].nil?

      next if regroupements[ node.name ][ node['Ident'] ].nil?

      node.children.each do |subnode|
        next unless %w(PartieDeClasse Classe Groupe).include? subnode.name

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
                FailedIdentification.create( import_id: etablissement.imports.last.id,
                                             date_creation: Time.now,
                                             sha256: sha256 )
              else
                regroupements[ subnode.name ][ subnode['Ident'] ] = manually_linked_id.id_annuaire
              end
            end

            rapport[subnode.name.to_sym][:error] << { sha256: sha256, objet: objet } if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
          end

          rapport[subnode.name.to_sym][:success] << { id: regroupements[ subnode.name ][ subnode['Ident'] ], nom: subnode['Nom'] } unless regroupements[ subnode.name ][ subnode['Ident'] ].nil?
        when 'Classe'
          reponse_annuaire = AnnuaireWrapper::Etablissement::Regroupement.search( etablissement.UAI, subnode['Nom'] )
          code_annuaire = reponse_annuaire.nil? || !( reponse_annuaire.is_a? Array ) ? nil : reponse_annuaire.first['id']
          regroupements[ subnode.name ][ subnode['Ident'] ] = code_annuaire
          if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
            objet = { UAI: etablissement.UAI, Nom: subnode['Nom'] }
            sha256 = Digest::SHA256.hexdigest( objet.to_json )

            manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
            if manually_linked_id.nil?
              FailedIdentification.create( import_id: etablissement.imports.last.id,
                                           date_creation: Time.now,
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

    [ regroupements, rapport ]
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

    xml
      .search('Cours/Cours')
      .each do |node|
      next if node.name == 'text' || node.key?( 'SemainesAnnulation' )
      LOGGER.debug '**** Parsing Cours ************************************************************'

      matiere_id = matieres[ node.search( 'Matiere' ).first.attributes['Ident'].value ]
      next if matiere_id.nil?
      LOGGER.debug "**** Matière: #{matiere_id}"

      this_creneau_regroupements = node.children.select { |subnode| %w(Classe PartieDeClasse Groupe).include? subnode.name }
      next if this_creneau_regroupements.empty?
      this_creneau_regroupements
        .select { |subnode| regroupements[ subnode.name ][ subnode['Ident'] ].nil? }
        .each { |subnode| rapport[:regroupements][:error] << "#{subnode['Ident']} (#{subnode.name})" }
      this_creneau_regroupements.reject! { |subnode| regroupements[ subnode.name ][ subnode['Ident'] ].nil? }
      this_creneau_regroupements.map! do |subnode|
        { id: regroupements[ subnode.name ][ subnode['Ident'] ].to_s,
          semainier: subnode['Semaines'] }
      end
      LOGGER.debug "**** Regroupements treated: #{this_creneau_regroupements}"

      this_creneau_enseignants = node.children.select { |subnode| subnode.name == 'Professeur' }
      next if this_creneau_enseignants.empty?
      this_creneau_enseignants = this_creneau_enseignants
                                 .map do |enseignant|
        e = enseignants[ enseignant['Ident'] ]
        next if e.nil? || e[:id].nil?
        e[:semainier] = enseignant['Semaines']

        e
      end.compact
      LOGGER.debug "**** Enseignants treated: #{this_creneau_enseignants}"
      next if ( this_creneau_regroupements.map { |r| r[:id].to_i } & this_creneau_enseignants.reduce([]) { |a, e| a.concat(e[:regroupements]) }.uniq ).empty?

      LOGGER.debug '****=EVERYTHING LOOKS GOOD, CONTINUING'

      this_creneau_salles = node.children
                                .select { |subnode| subnode.name == 'Salle' }
                                .map do |subnode_salle|
        { salle: Salle[ identifiant: subnode_salle['Ident'] ],
          semainier: subnode_salle['Semaines'] }
      end
      LOGGER.debug "  Salles: #{this_creneau_salles}"

      debut = PlageHoraire[ label: node['NumeroPlaceDebut'] ][:id]
      fin = PlageHoraire[ label: node['NumeroPlaceDebut'].to_i + node['NombrePlaces'].to_i - 1 ][:id]
      LOGGER.debug "**** From #{debut} to #{fin}"

      this_creneau_regroupements.each do |regroupement|
        # Retrieving or creating the creneau
        creneau = DataManagement::Accessors
                  .create_or_get( CreneauEmploiDuTemps,
                                  etablissement_id: etablissement.id,
                                  jour_de_la_semaine: node['Jour'],
                                  debut: debut,
                                  fin: fin,
                                  matiere_id: matiere_id )
        LOGGER.debug "**** \ Found or created #{creneau.id}"

        if !creneau.regroupements.empty? && !creneau.regroupements.map( &:regroupement_id ).include?( regroupement[:id] )
          creneau = CreneauEmploiDuTemps.create( etablissement_id: etablissement.id,
                                                 jour_de_la_semaine: node['Jour'],
                                                 debut: debut,
                                                 fin: fin,
                                                 matiere_id: matiere_id,
                                                 date_creation: Time.now )
          LOGGER.debug "**** \_ but create #{creneau.id} instead"
        end

        # adding regroupement if needed
        if creneau.regroupements.empty?
          CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
          creneau.add_regroupement( regroupement_id: regroupement[:id] )
          CreneauEmploiDuTempsRegroupement.restrict_primary_key
          LOGGER.debug "**** \\ add regroupement #{regroupement[:id]} to #{creneau.id}"
        end
        # updating semainier of regroupement
        cr = CreneauEmploiDuTempsRegroupement
             .where( regroupement_id: regroupement[:id] )
             .where( creneau_emploi_du_temps_id: creneau.id )
        cr.update(semaines_de_presence: corrige_semainiers( regroupement[:semainier], offset_semainiers ) )

        rapport[:regroupements][:success] << regroupement[:id]

        # adding enseignants
        this_creneau_enseignants
          .each do |enseignant|
          # adding enseignant
          unless creneau.enseignants.map( &:enseignant_id ).include?( enseignant[:id] )
            CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
            creneau.add_enseignant( enseignant_id: enseignant[:id] )
            CreneauEmploiDuTempsEnseignant.restrict_primary_key
            LOGGER.debug "**** \\ add enseignant #{enseignant[:id]}"
          end
          # updating enseignant's semainier
          ce = CreneauEmploiDuTempsEnseignant
               .where( enseignant_id: enseignant[:id] )
               .where( creneau_emploi_du_temps_id: creneau.id )
          ce.update(semaines_de_presence: corrige_semainiers( enseignant[:semainier], offset_semainiers ) )

          rapport[:enseignants][:success] << enseignant[:id]
        end

        # adding salles
        this_creneau_salles.each do |subnode_salle|
          # adding salle
          unless creneau.salles.include?( subnode_salle[:salle] )
            creneau.add_salle( subnode_salle[:salle] )
            LOGGER.debug "**** \\ add salle #{subnode_salle['Ident']}"
          end
          # updating salle's semainier
          cs = CreneauEmploiDuTempsSalle
               .where( salle_id: subnode_salle[:salle][:id] )
               .where( creneau_emploi_du_temps_id: creneau.id )
          cs.update(semaines_de_presence: corrige_semainiers( subnode_salle[:semainier], offset_semainiers ) )

          rapport[:salles][:success] << subnode_salle[:salle][:id]
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

  def load_xml( decrypted_xml, create_creneaux )
    rapport = {}

    edt_clair = Nokogiri::XML( decrypted_xml, &:noblanks )

    etablissement = load_etablissement( edt_clair, create_creneaux ? 1 : 0 )

    rapport[:plages_horaires] = load_plages_horaires( edt_clair )
    trace_rapport( rapport, :plages_horaires )

    rapport[:salles] = load_salles( edt_clair, etablissement )
    trace_rapport( rapport, :salles )

    ####
    # Les matières sont dans l'annuaire
    ####
    trace_rapport( rapport, :matieres )
    matieres, rapport[:matieres] = load_matieres( edt_clair, etablissement )

    ####
    # Les enseignants sont dans l'annuaire
    ####
    trace_rapport( rapport, :enseignants )
    enseignants, rapport[:enseignants] = load_enseignants( edt_clair, etablissement )

    ####
    # Les classes, parties de classe et groupes sont dans l'annuaire
    ####
    regroupements, rapport[:regroupements] = load_regroupements( edt_clair, etablissement )
    rapport[:regroupements].keys.each do |key|
      trace_rapport( rapport[:regroupements], key )
    end

    if create_creneaux
      LOGGER.debug 'Creating Créneaux'
      rapport[:creneaux] = load_creneaux( edt_clair, etablissement, matieres, enseignants, regroupements )
      # rapport[:creneaux].keys.each do |key|
      #   trace_rapport( rapport[:creneaux], key )
      # end

      provision_cahiers_de_textes
    end

    rapport
  end

  def decrypt_and_load_xml( xml, create_creneaux = false, _xsd = nil )
    load_xml( decrypt_xml( xml ), create_creneaux )
  end
end
# rubocop:enable Metrics/ModuleLength
