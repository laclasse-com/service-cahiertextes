# -*- coding: utf-8 -*-

require 'nokogiri'

require './models'

module ProNote
  def ProNote.decrypt_XML(encrypted_xml_file, xsd_file = nil)
    encrypted_xml = Nokogiri::XML(encrypted_xml_file)

    raise 'fichier XML invalide' unless xsd_file != nil && Nokogiri::XML::Schema(xsd_file).valid?(encrypted_xml)

    # TODO: Here be decryption magic
    xml = encrypted_xml_file
    xml
  end

  def ProNote.load_XML(xml_file, xsd_file = nil)
    edt_clair = Nokogiri::XML(xml_file)

    # TODO: use XSD defined in XML
    # if xsd_file != nil then
    #   xsd = Nokogiri::XML::Schema(xsd_file)
    #   if ! xsd.valid?(edt_clair) then
    #     p xsd.validate(edt_clair)
    #     return
    #   end
    # end

    etablissement = Etablissement.create(UAI: edt_clair.child['UAI'])

    edt_clair.search('AnneeScolaire').each do |node|
      if node.name != 'text' then
        etablissement.debut_annee_scolaire = node['DateDebut']
        etablissement.fin_annee_scolaire = node['DateFin']
        etablissement.date_premier_jour_premiere_semaine = node['DatePremierJourSemaine1']
        etablissement.save
      end
    end

    # Inutile, calculable à partir des plages horaires
    # edt_clair.search('GrilleHoraire').each do |node|
    #   print 'new ' + node.name + '(' +
    #     node['NombrePlacesParJour'] + ', ' +
    #     node['DureePlace'] + ')\n' unless node.name == 'text'
    # end

    edt_clair.search('PlacesParJour').children.each do
      |place|
      PlageHoraire.create(label: place['Numero'],
                          debut: place['LibelleHeureDebut'],
                          fin: place['LibelleHeureFin']) unless place.name == 'text'
    end

    # Les matières sont dans l'annuaire
    # edt_clair.search('Matieres').children.each do |matiere|
    #   print 'new ' + matiere.name + '(' +
    #     matiere['Ident'] + ', '' +
    #     matiere['Code'] + ', '' +
    #     matiere['Libelle'] + '')\n' unless matiere.name == 'text'
    # end

    # Les enseignants sont dans l'annuaire
    # edt_clair.search('Professeurs').children.each do |professeur|
    #   print 'new ' + professeur.name + '(' +
    #     professeur['Ident'] + ', '' +
    #     professeur['Nom'] + ', '' +
    #     professeur['Prenom'] + ', '' +
    #     professeur['CodePostal'] + '')\n' unless professeur.name == 'text'
    # end

    # Les classes sont dans l'annuaire
    # edt_clair.search('Classes').children.each do |classe|
    #   if classe.name != 'text' then
    #     print 'new ' + classe.name + '(' +
    #       classe['Ident'] + ', '' +
    #       classe['Nom'] + '')\n'
    #     classe.children.each do |partie_de_classe|
    #       print '  new ' + partie_de_classe.name + '(:parent => ' + classe['Ident'] + ', ' +
    #         partie_de_classe['Ident'] + ')\n' unless partie_de_classe.name == 'text'
    #     end
    #   end
    # end

    # Les groupes sont dans l'annuaire
    # edt_clair.search('Groupes').children.each do |groupe|
    #   if groupe.name != 'text' then
    #     print 'new ' + groupe.name + '(' +
    #       groupe['Ident'] + ', '' +
    #       groupe['Nom'] + '')\n'
    #     groupe.children.each do |node|
    #       case node.name
    #       when 'PartieDeClasse'
    #         print '  new ' + node.name + '(:parent => ' + groupe['Ident'] + ', ' +
    #           node['Ident'] + ')\n' unless node.name == 'text'
    #       when 'Classe'
    #         print '  new ' + node.name + '(:parent => ' + groupe['Ident'] + ', ' +
    #           node['Ident'] + ')\n' unless node.name == 'text'
    #       end
    #     end
    #   end
    # end

    edt_clair.search('Salles').children.each do |salle|
      Salle.create(identifiant: salle['Ident'],
                   nom: salle['Nom']) unless salle.name == 'text'
    end

    # Les élèves sont dans l'annuaire
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

    edt_clair.search('Cours/Cours').each do |creneau_emploi_du_temps|
      unless creneau_emploi_du_temps.name == 'text'
        debut = PlageHoraire.filter(label: creneau_emploi_du_temps['NumeroPlaceDebut']).first[:id]
        fin = PlageHoraire.filter(label: creneau_emploi_du_temps['NumeroPlaceDebut'].to_i + creneau_emploi_du_temps['NombrePlaces'].to_i).first[:id]
        matiere_id = 0

        creneau_emploi_du_temps.children.each do |node|  # FIXME: peut mieux faire
          node.name == 'Matiere' && matiere_id = node['Ident']
        end
        creneau = CreneauEmploiDuTemps.create(jour_de_la_semaine: creneau_emploi_du_temps['Jour'], # 1: 'lundi' .. 7: 'dimanche', norme ISO-8601
                                              debut: debut,
                                              fin: fin,
                                              matiere_id: matiere_id)
        creneau_emploi_du_temps.children.each do |node|
          case node.name
          when 'Professeur'
            CreneauEmploiDuTempsEnseignant.create(creneau_emploi_du_temps_id: creneau.id,
                                                  enseignant_id: node['Ident'],
                                                  semaines_de_presence: node['Semaines'])
          when 'Classe', 'PartieDeClasse', 'Groupe'
            # on ne distingue pas les 3 types de regroupements
            CreneauEmploiDuTempsRegroupement.create(creneau_emploi_du_temps_id: creneau.id,
                                                    regroupement_id: node['Ident'],
                                                    semaines_de_presence: node['Semaines'])
          when 'Salle'
            CreneauEmploiDuTempsSalle.create(creneau_emploi_du_temps_id: creneau.id,
                                             salle_id: Salle[identifiant: node['Ident']][:id],
                                             semaines_de_presence: node['Semaines'])
          end
        end

      end
    end

  end

end
