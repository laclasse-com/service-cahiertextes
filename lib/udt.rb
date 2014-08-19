# -*- coding: utf-8 -*-
require 'nokogiri'
require 'zip'

require_relative './annuaire'
require_relative '../models/models'

# Consomme le fichier Emploi du temps exporté par UDT
module UDT
  module_function

  def read_file_from_zip( zip, filename )
    zip.glob( filename ).first.get_input_stream.read
  end

  def load_zip( zip, uai )
    zip_file = Zip::File.open( zip )

    STDERR.puts 'chargement Etablissement'
    etablissement = Etablissement.create( UAI: uai )
    xml = Nokogiri::XML( read_file_from_zip( zip_file, 'UDCal_24.xml' ) )
    etablissement.debut_annee_scolaire = xml.search('debut_eleve').children.first.text
    etablissement.fin_annee_scolaire = xml.search('fin_eleve').children.first.text
    etablissement.date_premier_jour_premiere_semaine = etablissement.debut_annee_scolaire
    etablissement.save

    STDERR.puts 'chargement Plages Horaires'
    plages_horaires = {}
    xml = Nokogiri::XML( read_file_from_zip( zip_file, 'UDCal_07.xml' ) )
    xml.search( 'demi_seq' ).each do |demi_seq|
      p demi_seq
      plages_horaires[ demi_seq['code'] ] =  PlageHoraire.create(label: demi_seq['hre_deb'],
                                                                 debut: Time.parse( demi_seq['hre_deb'] ),
                                                                 fin: Time.parse( demi_seq['hre_fin'] ) ) unless demi_seq.name == 'text' || demi_seq['hre_deb'] == '' || demi_seq['hre_fin'] == ''
    end
    STDERR.puts

    STDERR.puts 'chargement Salles'
    xml = Nokogiri::XML( read_file_from_zip( zip_file, 'UDCal_03.xml' ) )
    xml.search( 'salle' ).each do |salle|
      Salle.create( etablissement_id: etablissement.id,
                    identifiant: salle['code'],
                    nom: salle['nom'] ) unless salle.name == 'text'
      STDERR.putc '.'
    end
    STDERR.puts

    ####
    # Les matières sont dans l'annuaire
    ####
    STDERR.puts 'chargement Matières'
    matieres = {}
    xml = Nokogiri::XML( read_file_from_zip( zip_file, 'UDCal_05.xml' ) )
    xml.search('mat').each do |matiere|
      matieres[ matiere['libelle'] ] = Annuaire.search_matiere( matiere['libelle'] )['id'] unless matiere.name == 'text' || matiere['code'] == '***'
      STDERR.putc '.'
    end
    STDERR.puts

    ####
    # Les enseignants sont dans l'annuaire
    # TODO: On va interroger l'annuaire pour construire une table de correspondance temporaire
    # entre ce que nous envoi ProNote et ce que nous avons dans l'annuaire.
    ####
    STDERR.puts 'chargement Enseignants'
    enseignants = {}
    xml = Nokogiri::XML( read_file_from_zip( zip_file, 'UDCal_04.xml' ) )
    xml.search('prof').each do |professeur|
      user_annuaire = Annuaire.search_utilisateur( etablissement.UAI, professeur['nom'], professeur['prenom'] )
      enseignants[ professeur['code'] ] = user_annuaire['id_ent'] unless user_annuaire.nil? || professeur.name == 'text'
      STDERR.putc '.'
    end
    STDERR.puts

    ####
    # Les classes, parties de classe et groupes sont dans l'annuaire
    # TODO: On va interroger l'annuaire pour construire une table de correspondance temporaire
    # entre ce que nous envoi ProNote et ce que nous avons dans l'annuaire.
    ####
    STDERR.puts 'chargement Regroupements'
    regroupements = {  }
    xml = Nokogiri::XML( read_file_from_zip( zip_file, 'UDCal_08.xml' ) )
    xml.search( 'div' ).each do |classe|
      unless classe.name == 'text'
        reponse_annuaire = Annuaire.search_regroupement( etablissement.UAI, classe['libelle'] )
        code_annuaire = reponse_annuaire['id'] unless reponse_annuaire.nil?
        regroupements[ classe['code'] ] = code_annuaire unless code_annuaire.nil?
        STDERR.putc 'c'
      end
    end
    xml = Nokogiri::XML( read_file_from_zip( zip_file, 'UDCal_13.xml' ) )
    xml.search( 'rgpmt' ).each do |groupe|
      unless groupe.name == 'text'
        reponse_annuaire = Annuaire.search_regroupement( etablissement.UAI, groupe['nom'] )
        code_annuaire = reponse_annuaire['id'] unless reponse_annuaire.nil?
        regroupements[ "#{groupe['code_div']}:#{groupe['nom']}" ] = code_annuaire unless code_annuaire.nil?
        STDERR.putc 'g'
      end
    end
    xml = Nokogiri::XML( read_file_from_zip( zip_file, 'UDCal_19.xml' ) )
    xml.search( 'gpe' ).each do |partiedeclasse|
      unless partiedeclasse.name == 'text' || partiedeclasse['code_sts'] == ''
        reponse_annuaire = Annuaire.search_regroupement( etablissement.UAI, partiedeclasse['code_sts'] )
        code_annuaire = reponse_annuaire['id'] unless reponse_annuaire.nil?
        regroupements[ partiedeclasse['code_sts'] ] = code_annuaire unless code_annuaire.nil?
        STDERR.putc 'p'
      end
    end

    STDERR.puts 'création des Cahier de Textes nécessaires'
    regroupements.each do |_, regroupement|
      CahierDeTextes.create( regroupement_id: regroupement )
    end

    STDERR.puts 'chargement Créneaux d\'Emploi du Temps'
    # Step 1: loading 'fiches'
    xml = Nokogiri::XML( read_file_from_zip( zip_file, 'UDCal_11.xml' ) )
    fiches = {}
    xml.search( 'fiche' ).each do |fiche|
      fiches[ fiche['code'] ] = fiche.to_h unless fiche.name == 'text'
    end
    # Step 2: loading 'ligfiches'
    xml = Nokogiri::XML( read_file_from_zip( zip_file, 'UDCal_12.xml' ) )
    xml.search( 'ligfiche' ).each do |ligfiche|
      unless ligfiche.name == 'text'
        fiche = fiches[ ligfiche['fic'] ]
        unless ligfiche['mat'] == '' #|| matieres[ ligfiche['mat'] ].nil?
          creneau = CreneauEmploiDuTemps.create( jour_de_la_semaine: fiche['jour'],
                                                 debut: plages_horaires[ fiche['demi_seq'] ],
                                                 fin: plages_horaires[ fiche['demi_seq'] ],
                                                 matiere_id: 'null' ) #matieres[ ligfiche['mat'] ])
          p creneau
        end
      end
    end

  end
end
