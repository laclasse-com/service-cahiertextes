# -*- coding: utf-8 -*-
require 'nokogiri'
require 'base64'
require 'openssl'
require 'zlib'

require_relative './annuaire'
require_relative '../models/models'

# Consomme le fichier Emploi du temps exporté par Pronote
module ProNote
  module_function

  def decrypt_wrapped_data( data, rsa_key_filename )
    pk = OpenSSL::PKey::RSA.new( File.read( rsa_key_filename ) )
    pk.private_decrypt data
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
    buf = zstream.inflate(string)
    zstream.finish
    zstream.close
    buf
  end

  def decrypt_xml( encrypted_xml )
    encrypted_edt_export_file = Nokogiri::XML( encrypted_xml )

    crypted_wrapped_data = Base64.decode64( encrypted_edt_export_file.search( 'PARTENAIRE' ).select { |part| part.attributes[ 'NOM' ].value == PRONOTE[:nom_integrateur] }.first.text )
    decrypted_wrapped_data = decrypt_wrapped_data( crypted_wrapped_data, PRONOTE[:cle_integrateur] )
    aes_secret_key = decrypted_wrapped_data[ 0..16 ]
    aes_iv = decrypted_wrapped_data[ 16..32 ]

    crypted_payload = Base64.decode64( encrypted_edt_export_file.search( 'CONTENU' ).first.text )

    decrypted_payload = decrypt_payload( crypted_payload, aes_secret_key, aes_iv )

    inflate decrypted_payload
  end

  def corrige_semainiers( semainier, decalage )
    semainier = semainier.to_i if semainier.is_a? String
    semainier = semainier.to_s 2
    pivot = semainier.length - decalage
    debut = semainier.slice( pivot, semainier.length )
    fin = semainier.slice( 0, pivot )

    "#{debut}#{fin}".to_i 2
  end

  def extract_uai_from_xml( xml, xsd = nil )
    edt_clair = Nokogiri::XML( decrypt_xml( xml ) )
    edt_clair.child['UAI']
  end

  def load_xml( xml, xsd = nil )
    rapport = {}
    edt_clair = Nokogiri::XML( decrypt_xml( xml ) )

    etablissement = Etablissement.where( UAI: edt_clair.child['UAI'] ).first
    etablissement = Etablissement.create(UAI: edt_clair.child['UAI']) if etablissement.nil?

    edt_clair.search('AnneeScolaire').reject { |child| child.name == 'text' }.each do |node|
      etablissement.debut_annee_scolaire = node['DateDebut']
      etablissement.fin_annee_scolaire = node['DateFin']
      etablissement.date_premier_jour_premiere_semaine = node['DatePremierJourSemaine1']
      etablissement.save
    end
    offset_semainiers = etablissement.date_premier_jour_premiere_semaine.cweek

    rapport[:plages_horaires] = { success: [], error: [] }
    edt_clair.search('PlacesParJour').children.reject { |child| child.name == 'text' }.each do |node|
      plage = PlageHoraire.create(label: node['Numero'],
                                  debut: node['LibelleHeureDebut'],
                                  fin: node['LibelleHeureFin'])

      if plage.nil?
        rapport[:plages_horaires][:error] << { label: node['Numero'],
                                               debut: node['LibelleHeureDebut'],
                                               fin: node['LibelleHeureFin'] }
      else
        rapport[:plages_horaires][:success] << plage
      end
    end

    rapport[:salles] =  { success: [], error: [] }
    edt_clair.search('Salles').children.reject { |child| child.name == 'text' }.each do |node|
      salle = Salle.create( etablissement_id: etablissement.id,
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

    ####
    # Les matières sont dans l'annuaire
    ####
    rapport[:matieres] = { success: [], error: [] }
    matieres = {}
    edt_clair.search('Matieres').children.reject { |child| child.name == 'text' }.each do |node|
      matieres[ node['Ident'] ] = Annuaire.search_matiere( node['Libelle'] )['id']
      if matieres[ node['Ident'] ].nil?
        objet = { Libelle: node['Libelle'] }
        sha256 = Digest::SHA256.hexdigest( objet.to_json )

        manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
        if manually_linked_id.nil? || manually_linked_id.id_annuaire.nil?
          FailedIdentification.create( date_creation: Time.now,
                                       sha256: sha256 ) if manually_linked_id.nil?
          rapport[:matieres][:error] << { sha256: sha256,
                                          objet: objet }
        else
          matieres[ node['Ident'] ] = manually_linked_id.id_annuaire
        end
      end
      unless matieres[ node['Ident'] ].nil?
        rapport[:matieres][:success] << matieres[ node['Ident'] ]
      end
    end

    ####
    # Les enseignants sont dans l'annuaire
    ####
    rapport[:enseignants] = { success: [], error: [] }
    enseignants = {}
    edt_clair.search('Professeurs').children.reject { |child| child.name == 'text' }.each do |node|
      user_annuaire = Annuaire.search_utilisateur( etablissement.UAI, node['Nom'], node['Prenom'] )
      enseignants[ node['Ident'] ] = user_annuaire.nil? ? nil : user_annuaire['id_ent']
      if enseignants[ node['Ident'] ].nil?
        objet = { UAI: etablissement.UAI, Nom: node['Nom'], Prenom: node['Prenom'] }
        sha256 = Digest::SHA256.hexdigest( objet.to_json )

        manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
        if manually_linked_id.nil? || manually_linked_id.id_annuaire.nil?
          FailedIdentification.create( date_creation: Time.now,
                                       sha256: sha256 ) if manually_linked_id.nil?
          rapport[:enseignants][:error] << { sha256: sha256,
                                             objet: objet }
        else
          enseignants[ node['Ident'] ] = manually_linked_id.id_annuaire
        end
      end

      unless enseignants[ node['Ident'] ].nil?
        rapport[:enseignants][:success] << enseignants[ node['Ident'] ]
      end
    end

    ####
    # Les classes, parties de classe et groupes sont dans l'annuaire
    ####
    rapport[:regroupements] = { Classe: { success: [], error: [] },
                                Groupe: { success: [], error: [] },
                                PartieDeClasse: { success: [], error: [] } }
    regroupements = { 'Classe' => {}, 'PartieDeClasse' => {}, 'Groupe' => {} }

    edt_clair.search('Classes').children.reject { |child| child.name == 'text' }.each do |node|
      reponse_annuaire = Annuaire.search_regroupement( etablissement.UAI, node['Nom'] )
      code_annuaire = reponse_annuaire.nil? ? nil : reponse_annuaire['id']
      regroupements[ node.name ][ node['Ident'] ] = code_annuaire
      if regroupements[ node.name ][ node['Ident'] ].nil?
        objet = { UAI: etablissement.UAI, Nom: node['Nom'] }
        sha256 = Digest::SHA256.hexdigest( objet.to_json )

        manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
        if manually_linked_id.nil? || manually_linked_id.id_annuaire.nil?
          FailedIdentification.create( date_creation: Time.now,
                                       sha256: sha256 ) if manually_linked_id.nil?
          rapport[:regroupements][node.name.to_sym][:error] << { sha256: sha256,
                                                                 objet: objet }
        else
          regroupements[ node.name ][ node['Ident'] ] = manually_linked_id.id_annuaire
        end
      end

      unless regroupements[ node.name ][ node['Ident'] ].nil?
        rapport[:regroupements][node.name.to_sym][:success] << regroupements[ node.name ][ node['Ident'] ]
      end

      unless regroupements[ 'Classe' ][ node['Ident'] ].nil?
        node.children.reject { |child| child.name == 'text' }.each do |subnode|
          if subnode['Nom'].nil?
            regroupements[ 'PartieDeClasse' ][ subnode['Ident'] ] = regroupements[ 'Classe' ][ node['Ident'] ]
          else
            reponse_annuaire = Annuaire.search_regroupement( etablissement.UAI, subnode['Nom'] )
            code_annuaire = reponse_annuaire.nil? ? nil : reponse_annuaire['id']
            regroupements[ subnode.name ][ subnode['Ident'] ] = code_annuaire
            if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
              objet = { UAI: etablissement.UAI, Nom: subnode['Nom'] }
              sha256 = Digest::SHA256.hexdigest( objet.to_json )

              manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
              if manually_linked_id.nil? || manually_linked_id.id_annuaire.nil?
                FailedIdentification.create( date_creation: Time.now,
                                             sha256: sha256 ) if manually_linked_id.nil?
                rapport[:regroupements][subnode.name.to_sym][:error] << { sha256: sha256,
                                                                          objet: objet }
              else
                regroupements[ subnode.name ][ subnode['Ident'] ] = manually_linked_id.id_annuaire
              end
            end
          end

          unless regroupements[ subnode.name ][ subnode['Ident'] ].nil?
            rapport[:regroupements][subnode.name.to_sym][:success] << regroupements[ subnode.name ][ subnode['Ident'] ]
          end
        end
      end
    end
    edt_clair.search('Groupes').children.reject { |child| child.name == 'text' }.each do |node|
      reponse_annuaire = Annuaire.search_regroupement( etablissement.UAI, node['Nom'] )
      code_annuaire = reponse_annuaire.nil? ? nil : reponse_annuaire['id']
      regroupements[ node.name ][ node['Ident'] ] = code_annuaire
      if regroupements[ node.name ][ node['Ident'] ].nil?
        objet = { UAI: etablissement.UAI, Nom: node['Nom'] }
        sha256 = Digest::SHA256.hexdigest( objet.to_json )

        manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
        if manually_linked_id.nil? || manually_linked_id.id_annuaire.nil?
          FailedIdentification.create( date_creation: Time.now,
                                       sha256: sha256 ) if manually_linked_id.nil?
          rapport[:regroupements][node.name.to_sym][:error] << { sha256: sha256,
                                                                 objet: objet }
        else
          regroupements[ node.name ][ node['Ident'] ] = manually_linked_id.id_annuaire
        end
      end

      unless regroupements[ node.name ][ node['Ident'] ].nil?
        rapport[:regroupements][node.name.to_sym][:success] << regroupements[ node.name ][ node['Ident'] ]
      end

      unless regroupements[ node.name ][ node['Ident'] ].nil?
        node.children.each do |subnode|
          case subnode.name
          when 'PartieDeClasse'
            if subnode['Nom'].nil?
              regroupements[ 'PartieDeClasse' ][ subnode['Ident'] ] = regroupements[ 'Classe' ][ node['Ident'] ]
            else
              reponse_annuaire = Annuaire.search_regroupement( etablissement.UAI, subnode['Nom'] )
              code_annuaire = reponse_annuaire.nil? ? nil : reponse_annuaire['id']
              regroupements[ subnode.name ][ subnode['Ident'] ] = code_annuaire
              if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
                objet = { UAI: etablissement.UAI, Nom: subnode['Nom'] }
                sha256 = Digest::SHA256.hexdigest( objet.to_json )

                manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
                if manually_linked_id.nil? || manually_linked_id.id_annuaire.nil?
                  FailedIdentification.create( date_creation: Time.now,
                                               sha256: sha256 ) if manually_linked_id.nil?
                  rapport[:regroupements][subnode.name.to_sym][:error] << { sha256: sha256,
                                                                            objet: objet }
                else
                  regroupements[ subnode.name ][ subnode['Ident'] ] = manually_linked_id.id_annuaire
                end
              end
            end
            unless regroupements[ subnode.name ][ subnode['Ident'] ].nil?
              rapport[:regroupements][subnode.name.to_sym][:success] << regroupements[ subnode.name ][ subnode['Ident'] ]
            end
          when 'Classe'
            unless subnode.name == 'text'
              reponse_annuaire = Annuaire.search_regroupement( etablissement.UAI, subnode['Nom'] )
              code_annuaire = reponse_annuaire.nil? ? nil : reponse_annuaire['id']
              regroupements[ subnode.name ][ subnode['Ident'] ] = code_annuaire
              if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
                objet = { UAI: etablissement.UAI, Nom: subnode['Nom'] }
                sha256 = Digest::SHA256.hexdigest( objet.to_json )

                manually_linked_id = FailedIdentification.where( sha256: sha256 ).first
                if manually_linked_id.nil? || manually_linked_id.id_annuaire.nil?
                  FailedIdentification.create( date_creation: Time.now,
                                               sha256: sha256 ) if manually_linked_id.nil?
                  rapport[:regroupements][subnode.name.to_sym][:error] << { sha256: sha256,
                                                                            objet: objet }
                else
                  regroupements[ subnode.name ][ subnode['Ident'] ] = manually_linked_id.id_annuaire
                end
              end

              unless regroupements[ subnode.name ][ subnode['Ident'] ].nil?
                rapport[:regroupements][subnode.name.to_sym][:success] << regroupements[ subnode.name ][ subnode['Ident'] ]
              end
            end
          end
        end
      end
    end

    rapport[:creneaux] = { matieres: { success: [], error: [] },
                           enseignants: { success: [], error: [] },
                           regroupements: { success: [], error: [] },
                           salles: { success: [], error: [] } }
    edt_clair.search('Cours/Cours').reject { |child| child.name == 'text' }.each do |node|
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
      unless matiere_id.nil?
        creneau = CreneauEmploiDuTemps.create( date_creation: Time.now,
                                               jour_de_la_semaine: node['Jour'].to_i + etablissement.date_premier_jour_premiere_semaine.wday, # 1: 'lundi' .. 7: 'dimanche', norme ISO-8601
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
              CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
              creneau.add_enseignant(enseignant_id: enseignants[ subnode['Ident'] ],
                                     semaines_de_presence: corrige_semainiers( subnode['Semaines'], offset_semainiers ) )
              CreneauEmploiDuTempsEnseignant.restrict_primary_key
            end
          when 'Classe', 'PartieDeClasse', 'Groupe' # on ne distingue pas les 3 types de regroupements
            if regroupements[ subnode.name ][ subnode['Ident'] ].nil?
              rapport[:creneaux][:regroupements][:error] << "#{subnode['Ident']} (#{subnode.name})"
            else
              rapport[:creneaux][:regroupements][:success] << regroupements[ subnode.name ][ subnode['Ident'] ]
              CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
              creneau.add_regroupement(regroupement_id: regroupements[ subnode.name ][ subnode['Ident'] ],
                                       semaines_de_presence: corrige_semainiers( subnode['Semaines'], offset_semainiers ) )
              CreneauEmploiDuTempsRegroupement.restrict_primary_key
            end
          when 'Salle'
            # CreneauEmploiDuTempsSalle.unrestrict_primary_key
            # creneau.add_salle(salle_id: Salle[ identifiant: subnode['Ident'] ][:id],
            #                   semaines_de_presence: corrige_semainiers( subnode['Semaines'], offset_semainiers ) )
            # CreneauEmploiDuTempsSalle.restrict_primary_key
            creneau.add_salle( Salle[ identifiant: subnode['Ident'] ] )
            cs = CreneauEmploiDuTempsSalle.where( salle_id: Salle[ identifiant: subnode['Ident'] ][:id] )
                                          .where( creneau_emploi_du_temps_id: creneau.id )
            cs.update(semaines_de_presence: corrige_semainiers( subnode['Semaines'], offset_semainiers ) )
            # cs.save
          end
        end
      end
    end

    CreneauEmploiDuTempsRegroupement
      .select(:regroupement_id)
      .map { |r| r.regroupement_id }
      .uniq
      .each do |regroupement_id|
      CahierDeTextes.create( date_creation: Time.now,
                             regroupement_id: regroupement_id ) unless CahierDeTextes.where( regroupement_id: regroupement_id ).count > 0
    end

    rapport
  end
end
