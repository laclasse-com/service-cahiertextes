# -*- coding: utf-8 -*-
require 'nokogiri'
require 'base64'
require 'openssl'
require 'zipruby'

require_relative './annuaire'
require_relative '../models/models'

# Consomme le fichier Emploi du temps exporté par Pronote
module ProNote
  module_function

  def decrypt_xml(encrypted_xml, xsd = nil)
    encrypted_xml = Nokogiri::XML(encrypted_xml)

    # fail 'fichier XML invalide' unless !xsd.nil? && Nokogiri::XML::Schema( xsd ).valid?( encrypted_xml )

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

    # FIXME: OpenSSL::PKey::RSAError: padding check failed
    hxml[:cles_AES] = pk.private_decrypt hxml[:cles_chiffrees_debased64]

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

    hxml[:contenu]
  end

  def load_xml(xml, xsd = nil)
    edt_clair = Nokogiri::XML(xml)

    # TODO: use XSD defined in XML
    # if xsd != nil then
    #   xsd = Nokogiri::XML::Schema(xsd)
    #   if ! xsd.valid?(edt_clair) then
    #     p xsd.validate(edt_clair)
    #     return
    #   end
    # end

    STDERR.puts 'chargement Etablissement'
    etablissement = Etablissement.create(UAI: edt_clair.child['UAI'])

    edt_clair.search('AnneeScolaire').each do |node|
      if node.name != 'text'
        etablissement.debut_annee_scolaire = node['DateDebut']
        etablissement.fin_annee_scolaire = node['DateFin']
        etablissement.date_premier_jour_premiere_semaine = node['DatePremierJourSemaine1']
        etablissement.save
        STDERR.putc '.'
      end
      STDERR.puts
    end

    STDERR.puts 'chargement Plages Horaires'
    edt_clair.search('PlacesParJour').children.each do
      |place|
      PlageHoraire.create(label: place['Numero'],
                          debut: place['LibelleHeureDebut'],
                          fin: place['LibelleHeureFin']) unless place.name == 'text'
      STDERR.putc '.'
    end
    STDERR.puts

    STDERR.puts 'chargement Salles'
    edt_clair.search('Salles').children.each do |salle|
      Salle.create(etablissement_id: etablissement.id,
                   identifiant: salle['Ident'],
                   nom: salle['Nom']) unless salle.name == 'text'
      STDERR.putc '.'
    end
    STDERR.puts

    # Inutile, calculable à partir des plages horaires
    # edt_clair.search('GrilleHoraire').each do |node|
    #   print 'new ' + node.name + '(' +
    #     node['NombrePlacesParJour'] + ', ' +
    #     node['DureePlace'] + ')\n' unless node.name == 'text'
    # end

    ####
    # Les matières sont dans l'annuaire
    ####
    matieres = {}
    STDERR.puts 'chargement Matières'
    edt_clair.search('Matieres').children.each do |matiere|
      matieres[ matiere['Ident'] ] = Annuaire.search_matiere( matiere['Libelle'] )['id'] unless matiere.name == 'text'
      STDERR.putc '.'
    end
    STDERR.puts

    ####
    # Les enseignants sont dans l'annuaire
    # TODO: On va interroger l'annuaire pour construire une table de correspondance temporaire
    # entre ce que nous envoi ProNote et ce que nous avons dans l'annuaire.
    ####
    enseignants = {}
    STDERR.puts 'chargement Enseignants'
    edt_clair.search('Professeurs').children.each do |professeur|
      enseignants[ professeur['Ident'] ] = Annuaire.search_utilisateur( etablissement.UAI, professeur['Nom'], professeur['Prenom'] )['id_ent'] unless professeur.name == 'text'
      STDERR.putc '.'
    end
    STDERR.puts

    ####
    # Les classes, parties de classe et groupes sont dans l'annuaire
    # TODO: On va interroger l'annuaire pour construire une table de correspondance temporaire
    # entre ce que nous envoi ProNote et ce que nous avons dans l'annuaire.
    ####
    regroupements = { 'Classe' => {}, 'PartieDeClasse' => {}, 'Groupe' => {} }
    STDERR.puts 'chargement Regroupements'
    edt_clair.search('Classes').children.each do |classe|
      unless classe.name == 'text'
        code_annuaire = Annuaire.search_regroupement( etablissement.UAI, classe['Nom'] )['id']
        regroupements[ 'Classe' ][ classe['Ident'] ] = code_annuaire
        STDERR.putc 'c'
      end
      classe.children.each do |partie_de_classe|
        unless partie_de_classe.name == 'text' || partie_de_classe['Nom'].nil?
          code_annuaire = Annuaire.search_regroupement( etablissement.UAI, partie_de_classe['Nom'] )['id']
          regroupements[ 'PartieDeClasse' ][ partie_de_classe['Ident'] ] = code_annuaire
          STDERR.putc 'p'
        end
      end
    end
    edt_clair.search('Groupes').children.each do |groupe|
      unless groupe.name == 'text'
        code_annuaire = Annuaire.search_regroupement( etablissement.UAI, groupe['Nom'] )['id']
        regroupements[ 'Groupe' ][ groupe['Ident'] ] = code_annuaire
        STDERR.putc 'g'
      end
      groupe.children.each do  |node|
        case node.name
        when 'PartieDeClasse'
          unless node.name == 'text' || node['Nom'].nil?
            code_annuaire = Annuaire.search_regroupement( etablissement.UAI, node['Nom'] )['id']
            regroupements[ 'PartieDeClasse' ][ node['Ident'] ] = code_annuaire
            STDERR.putc 'p'
          end
        when 'Classe'
          unless node.name == 'text'
            code_annuaire = Annuaire.search_regroupement( etablissement.UAI, classe['Nom'] )['id']
            regroupements[ 'Classe' ][ node['Ident'] ] = code_annuaire
            STDERR.putc 'c'
          end
        end
      end
    end
    STDERR.puts

    ####
    # Les élèves sont dans l'annuaire
    # TODO: On va interroger l'annuaire pour construire une table de correspondance temporaire
    # entre ce que nous envoi ProNote et ce que nous avons dans l'annuaire.
    # ou pas
    ####
    # edt_clair.search('Eleves').children.each do |eleve|
    #   print 'new ' + eleve.name +
    #     '(' + eleve['Ident'] +
    #     ', '' + eleve['Nom'] + '', '' +
    #     ', '' + eleve['Prenom'] + '', '' +
    #     ', '' + (eleve['DateNaissance'] or '') + '', '' +
    #     ', '' + eleve['Sexe'] + '', '' +
    #     ', '' + (eleve['CodePostal'] or '') + '', '' +
    #     ', '' + (eleve['NumeroNational'] or '') +
    #     '')\n' unless eleve.name == 'text'
    #   eleve.children.each do |node|
    #     case node.name
    #     when 'Responsable'
    #       print '  new ' + node.name +
    #         '(:eleve => ' + eleve['Ident'] +
    #         ', ' + node['Ident'] +
    #         ', ' + node['RespLegal'] +
    #         ', '' + node['Nom'] + '', '' +
    #         ', '' + node['Prenom'] + '', '' +
    #         ', '' + (node['Civilite'] or '') + '', '' +
    #         ', '' + node['Adresse1'] + '', '' +
    #         ', '' + node['CodePostal'] + '', '' +
    #         ', '' + node['Ville'] +
    #         '')\n' unless node.name == 'text'
    #     when 'Classe'
    #       print '  link Eleve(' + eleve['Ident'] + ') to Classe(' + node['Ident'] + ') from ' + node['DateEntree'] + ' to ' + node['DateSortie'] + '\n'
    #     when 'PartieDeClasse'
    #       print '  link Eleve(' + eleve['Ident'] + ') to PartieDeClasse(' + node['Ident'] + ') from ' + node['DateEntree'] + ' to ' + node['DateSortie'] + '\n'
    #     end
    #   end
    # end

    STDERR.puts 'chargement Créneaux d\'Emploi du Temps'
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
                STDERR.puts "Impossible de créer ce créneau car l'enseignant #{node['Ident']} n'a pu être indentifié"
              else
                CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
                creneau.add_enseignant(enseignant_id: enseignants[ node['Ident'] ],
                                       semaines_de_presence: node['Semaines'] )
                CreneauEmploiDuTempsEnseignant.restrict_primary_key
              end
            when 'Classe', 'PartieDeClasse', 'Groupe' # on ne distingue pas les 3 types de regroupements
              if regroupements[ node['Ident'] ].nil?
                STDERR.puts "Impossible de créer ce créneau car le regroupement #{node['Ident']} n'a pu être indentifié"
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
          STDERR.putc '.'
        end
      end
    end
    STDERR.puts

    STDERR.puts 'création des Cahier de Textes nécessaires'
    CreneauEmploiDuTempsRegroupement
    .select(:regroupement_id)
    .map { |r| r.regroupement_id }
    .uniq
    .each {
      |regroupement_id|
      CahierDeTextes.create( regroupement_id: regroupement_id ) unless CahierDeTextes.where( regroupement_id: regroupement_id ).count > 0
      STDERR.putc '.'
    }
    STDERR.puts

  end

end
