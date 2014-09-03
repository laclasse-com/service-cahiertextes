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

  def load_xml(xml, xsd = nil)
    rapport = {}
    edt_clair = Nokogiri::XML( decrypt_xml( xml ) )

    etablissement = Etablissement.create(UAI: edt_clair.child['UAI'])

    edt_clair.search('AnneeScolaire').each do |node|
      if node.name != 'text'
        etablissement.debut_annee_scolaire = node['DateDebut']
        etablissement.fin_annee_scolaire = node['DateFin']
        etablissement.date_premier_jour_premiere_semaine = node['DatePremierJourSemaine1']
        etablissement.save
      end
    end

    rapport[:plages_horaires] = { success: [], error: [] }
    edt_clair.search('PlacesParJour').children.each do
      |place|
      unless place.name == 'text'
        plage = PlageHoraire.create(label: place['Numero'],
                                    debut: place['LibelleHeureDebut'],
                                    fin: place['LibelleHeureFin'])

        rapport[:plages_horaires][:success] << plage unless plage.nil?
      end
    end

    rapport[:salles] =  { success: [], error: [] }
    edt_clair.search('Salles').children.each do |salle|
      unless salle.name == 'text'
        salle = Salle.create(etablissement_id: etablissement.id,
                             identifiant: salle['Ident'],
                             nom: salle['Nom'])

        rapport[:salles][:success] << salle unless salle.nil?
      end
    end

    ####
    # Les matières sont dans l'annuaire
    ####
    rapport[:matieres] = { success: [], error: [] }
    matieres = {}
    edt_clair.search('Matieres').children.each do |matiere|
      unless matiere.name == 'text'
        matieres[ matiere['Ident'] ] = Annuaire.search_matiere( matiere['Libelle'] )['id']

        rapport[:matieres][:success] << matieres[ matiere['Ident'] ] unless matieres[ matiere['Ident'] ].nil?
        rapport[:matieres][:error] << matiere if matieres[ matiere['Ident'] ].nil?
      end
    end
    ####
    # Les enseignants sont dans l'annuaire
    # TODO: On va interroger l'annuaire pour construire une table de correspondance temporaire
    # entre ce que nous envoi ProNote et ce que nous avons dans l'annuaire.
    ####
    rapport[:enseignants] = { success: [], error: [] }
    enseignants = {}
    edt_clair.search('Professeurs').children.each do |professeur|
      unless professeur.name == 'text'
        user_annuaire = Annuaire.search_utilisateur( etablissement.UAI, professeur['Nom'], professeur['Prenom'] )
        enseignants[ professeur['Ident'] ] = user_annuaire['id_ent'] unless user_annuaire.nil?

        rapport[:enseignants][:success] << enseignants[ professeur['Ident'] ] unless user_annuaire.nil?
        rapport[:enseignants][:error] << professeur if user_annuaire.nil?
      end
    end

    ####
    # Les classes, parties de classe et groupes sont dans l'annuaire
    # TODO: On va interroger l'annuaire pour construire une table de correspondance temporaire
    # entre ce que nous envoi ProNote et ce que nous avons dans l'annuaire.
    ####
    rapport[:regroupements] = { classes: { success: [], error: [] },
                                groupes: { success: [], error: [] },
                                parties_de_classe: { success: [], error: [] } }
    regroupements = { 'Classe' => {}, 'PartieDeClasse' => {}, 'Groupe' => {} }
    edt_clair.search('Classes').children.each do |classe|
      unless classe.name == 'text'
        reponse_annuaire = Annuaire.search_regroupement( etablissement.UAI, classe['Nom'] )
        code_annuaire = reponse_annuaire['id'] unless reponse_annuaire.nil?
        regroupements[ 'Classe' ][ classe['Ident'] ] = code_annuaire

        rapport[:regroupements][:classes][:success] << regroupements[ 'Classe' ][ classe['Ident'] ] unless regroupements[ 'Classe' ][ classe['Ident'] ].nil?
        rapport[:regroupements][:classes][:error] << classe if regroupements[ 'Classe' ][ classe['Ident'] ].nil?
      end
      classe.children.each do |partie_de_classe|
        unless partie_de_classe.name == 'text' || partie_de_classe['Nom'].nil?
          reponse_annuaire = Annuaire.search_regroupement( etablissement.UAI, partie_de_classe['Nom'] )
          code_annuaire = reponse_annuaire['id'] unless reponse_annuaire.nil?
          regroupements[ 'PartieDeClasse' ][ partie_de_classe['Ident'] ] = code_annuaire

          rapport[:regroupements][:parties_de_classe][:success] << regroupements[ 'PartieDeClasse' ][ partie_de_classe['Ident'] ] unless regroupements[ 'Classe' ][ classe['Ident'] ].nil?
          rapport[:regroupements][:parties_de_classe][:error] << partie_de_classe if regroupements[ 'PartieDeClasse' ][ classe['Ident'] ].nil?
        end
      end
    end
    edt_clair.search('Groupes').children.each do |groupe|
      unless groupe.name == 'text'
        reponse_annuaire = Annuaire.search_regroupement( etablissement.UAI, groupe['Nom'] )
        code_annuaire = reponse_annuaire['id'] unless reponse_annuaire.nil?
        regroupements[ 'Groupe' ][ groupe['Ident'] ] = code_annuaire

        rapport[:regroupements][:groupes][:success] << regroupements[ 'Groupe' ][ groupe['Ident'] ] unless regroupements[ 'Groupe' ][ groupe['Ident'] ].nil?
        rapport[:regroupements][:groupes][:error] << groupe if regroupements[ 'Groupe' ][ groupe['Ident'] ].nil?
      end
      groupe.children.each do  |node|
        case node.name
        when 'PartieDeClasse'
          unless node.name == 'text' || node['Nom'].nil?
            reponse_annuaire = Annuaire.search_regroupement( etablissement.UAI, node['Nom'] )
            code_annuaire = reponse_annuaire['id'] unless reponse_annuaire.nil?
            regroupements[ 'PartieDeClasse' ][ node['Ident'] ] = code_annuaire

            rapport[:regroupements][:parties_de_classe][:success] << regroupements[ 'PartieDeClasse' ][ node['Ident'] ] unless regroupements[ 'Classe' ][ classe['Ident'] ].nil?
            rapport[:regroupements][:parties_de_classe][:error] << node if regroupements[ 'PartieDeClasse' ][ classe['Ident'] ].nil?
          end
        when 'Classe'
          unless node.name == 'text'
            reponse_annuaire = Annuaire.search_regroupement( etablissement.UAI, classe['Nom'] )
            code_annuaire = reponse_annuaire['id'] unless reponse_annuaire.nil?
            regroupements[ 'Classe' ][ node['Ident'] ] = code_annuaire

            rapport[:regroupements][:classes][:success] << regroupements[ 'Classe' ][ node['Ident'] ] unless regroupements[ 'Classe' ][ classe['Ident'] ].nil?
            rapport[:regroupements][:classes][:error] << node if regroupements[ 'Classe' ][ classe['Ident'] ].nil?
          end
        end
      end
    end

    rapport[:creneaux] = { success: [], error: [] }
    edt_clair.search('Cours/Cours').each do |creneau_emploi_du_temps|
      unless creneau_emploi_du_temps.name == 'text'
        debut = PlageHoraire[ label: creneau_emploi_du_temps['NumeroPlaceDebut'] ][:id]
        fin = PlageHoraire[ label: creneau_emploi_du_temps['NumeroPlaceDebut'].to_i + creneau_emploi_du_temps['NombrePlaces'].to_i - 1 ][:id]
        matiere_id = nil

        creneau_emploi_du_temps.children.each do |node|  # FIXME: peut sûrement mieux faire
          matiere_id = matieres[ node['Ident'] ] if node.name == 'Matiere'
        end
        unless matiere_id.nil?
          creneau = CreneauEmploiDuTemps.create(jour_de_la_semaine: creneau_emploi_du_temps['Jour'].to_i + etablissement.date_premier_jour_premiere_semaine.wday, # 1: 'lundi' .. 7: 'dimanche', norme ISO-8601
                                                debut: debut,
                                                fin: fin,
                                                matiere_id: matiere_id)
          creneau_emploi_du_temps.children.each do |node|
            case node.name
            when 'Professeur'
              if enseignants[ node['Ident'] ].nil?
                rapport[:creneaux][:error] << node
              else
                CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
                creneau.add_enseignant(enseignant_id: enseignants[ node['Ident'] ],
                                       semaines_de_presence: node['Semaines'] )
                CreneauEmploiDuTempsEnseignant.restrict_primary_key
              end
            when 'Classe', 'PartieDeClasse', 'Groupe' # on ne distingue pas les 3 types de regroupements
              if regroupements[ node['Ident'] ].nil?
                rapport[:creneaux][:error] << node
              else
                CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
                creneau.add_regroupement(regroupement_id: regroupements[ node.name ][ node['Ident'] ],
                                         semaines_de_presence: node['Semaines'] )
                CreneauEmploiDuTempsRegroupement.restrict_primary_key
              end
            when 'Salle'
              CreneauEmploiDuTempsSalle.unrestrict_primary_key
              creneau.add_salle(salle_id: Salle[ identifiant: node['Ident'] ][:id],
                                semaines_de_presence: node['Semaines'] )
              CreneauEmploiDuTempsSalle.restrict_primary_key
            end
          end
        end
      end
    end

    CreneauEmploiDuTempsRegroupement
    .select(:regroupement_id)
    .map { |r| r.regroupement_id }
    .uniq
    .each {
      |regroupement_id|
      CahierDeTextes.create( regroupement_id: regroupement_id ) unless CahierDeTextes.where( regroupement_id: regroupement_id ).count > 0
    }

    rapport
  end
end
