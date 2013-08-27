# -*- coding: utf-8 -*-

require 'nokogiri'

require_relative '../models/models'

module ProNote
  def ProNote.decrypt_XML(encrypted_xml, xsd = nil)
    encrypted_xml = Nokogiri::XML(encrypted_xml)

    raise 'fichier XML invalide' unless xsd != nil && Nokogiri::XML::Schema(xsd).valid?(encrypted_xml)

    # TODO: Here be decryption magic
    xml = encrypted_xml
    xml
  end

  def ProNote.load_XML(xml, xsd = nil)
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
      if node.name != 'text' then
        etablissement.debut_annee_scolaire = node['DateDebut']
        etablissement.fin_annee_scolaire = node['DateFin']
        etablissement.date_premier_jour_premiere_semaine = node['DatePremierJourSemaine1']
        etablissement.save
      end
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
    # TODO: On va interroger l'annuaire pour construire une table de correspondance temporaire
    # entre ce que nous envoi ProNote et ce que nous avons dans l'annuaire.
    ####
    matieres = Hash.new
    STDERR.puts 'chargement Matières'
    edt_clair.search('Matieres').children.each do |matiere|
      # FIXME: pull from Annuaire
      code_annuaire = rand(100000..999999)
      matieres[ matiere['Ident'] ] = code_annuaire unless matiere.name == 'text'
      STDERR.putc '.'
    end
    STDERR.puts

    ####
    # Les enseignants sont dans l'annuaire
    # TODO: On va interroger l'annuaire pour construire une table de correspondance temporaire
    # entre ce que nous envoi ProNote et ce que nous avons dans l'annuaire.
    ####
    enseignants = Hash.new
    STDERR.puts 'chargement Enseignants'
    edt_clair.search('Professeurs').children.each do |professeur|
      # FIXME: pull from Annuaire
      code_annuaire = rand(100000..999999)
      enseignants[ professeur['Ident'] ] = code_annuaire unless professeur.name == 'text'
      STDERR.putc '.'
    end
    STDERR.puts

    ####
    # Les classes, parties de classe et groupes sont dans l'annuaire
    # TODO: On va interroger l'annuaire pour construire une table de correspondance temporaire
    # entre ce que nous envoi ProNote et ce que nous avons dans l'annuaire.
    ####
    regroupements = Hash.new
    regroupements[ 'Classe' ] = Hash.new
    regroupements[ 'PartieDeClasse' ] = Hash.new
    regroupements[ 'Groupe' ] = Hash.new
    STDERR.puts 'chargement Regroupements'
    edt_clair.search('Classes').children.each do |classe|
      # FIXME: pull from Annuaire
      code_annuaire = rand(100000..999999)
      regroupements[ 'Classe' ][ classe['Ident'] ] = code_annuaire unless classe.name == 'text'
      STDERR.putc '.'
      classe.children.each do |partie_de_classe|
        # FIXME: pull from Annuaire
        code_annuaire = rand(100000..999999)
        regroupements[ 'PartieDeClasse' ][ partie_de_classe['Ident'] ] = code_annuaire unless partie_de_classe.name == 'text'
        STDERR.putc '.'
      end
    end
    edt_clair.search('Groupes').children.each do |groupe|
      # FIXME: pull from Annuaire
      code_annuaire = rand(100000..999999)
      regroupements[ 'Groupe' ][ groupe['Ident'] ] = code_annuaire unless groupe.name == 'text'
      STDERR.putc '.'
      groupe.children.each do  |node|
        case node.name
        when 'PartieDeClasse'
          # FIXME: pull from Annuaire
          code_annuaire = rand(100000..999999)
          regroupements[ 'PartieDeClasse' ][ node['Ident'] ] = code_annuaire unless node.name == 'text'
          STDERR.putc '.'
        when 'Classe'
          # FIXME: pull from Annuaire
          code_annuaire = rand(100000..999999)
          regroupements[ 'Classe' ][ node['Ident'] ] = code_annuaire unless node.name == 'text'
          STDERR.putc '.'
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
        debut = PlageHoraire.filter(label: creneau_emploi_du_temps['NumeroPlaceDebut']).first[:id]
        fin = PlageHoraire.filter(label: creneau_emploi_du_temps['NumeroPlaceDebut'].to_i + creneau_emploi_du_temps['NombrePlaces'].to_i).first[:id]
        matiere_id = 0

        creneau_emploi_du_temps.children.each do |node|  # FIXME: peut sûrement mieux faire
          node.name == 'Matiere' && matiere_id = matieres[ node['Ident'] ]
        end
        creneau = CreneauEmploiDuTemps.create(jour_de_la_semaine: creneau_emploi_du_temps['Jour'], # 1: 'lundi' .. 7: 'dimanche', norme ISO-8601
                                              debut: debut,
                                              fin: fin,
                                              matiere_id: matiere_id)
        creneau_emploi_du_temps.children.each do |node|
          case node.name
          when 'Professeur'
            CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
            CreneauEmploiDuTempsEnseignant.create(creneau_emploi_du_temps_id: creneau.id,
                                                  enseignant_id: enseignants[ node['Ident'] ], # TODO: remplacer par notre id annuaire
                                                  semaines_de_presence: node['Semaines'])
            CreneauEmploiDuTempsEnseignant.restrict_primary_key
          when 'Classe', 'PartieDeClasse', 'Groupe' # on ne distingue pas les 3 types de regroupements
            CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
            CreneauEmploiDuTempsRegroupement.create(creneau_emploi_du_temps_id: creneau.id,
                                                    regroupement_id: regroupements[ node.name ][ node['Ident'] ], # TODO: remplacer par notre id annuaire
                                                    semaines_de_presence: node['Semaines'])
            CreneauEmploiDuTempsRegroupement.restrict_primary_key
          when 'Salle'
            CreneauEmploiDuTempsSalle.unrestrict_primary_key
            CreneauEmploiDuTempsSalle.create(creneau_emploi_du_temps_id: creneau.id,
                                             salle_id: Salle[ identifiant: node['Ident'] ][:id],
                                             semaines_de_presence: node['Semaines'])
            CreneauEmploiDuTempsSalle.restrict_primary_key
          end
        end
        STDERR.putc '.'
      end
    end
    STDERR.puts

  end

end
