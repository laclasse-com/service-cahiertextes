# -*- coding: utf-8 -*-

require_relative '../models/models'

module DataManagement
  # Layer over models
  module Accessors
    module_function

    def create_or_get( classe, params )
      objet = classe.where( params ).first

      objet = classe.create( params ) if objet.nil?
      objet.update( date_creation: Time.now ) if classe.method_defined? :date_creation

      objet
    end
  end

  # Fonctions de nettoyage des données
  module Cleansing
    module_function

    def unfinished_creneaux
      CreneauEmploiDuTemps.where( matiere_id: '' )
                          .all
                          .select { |c| c.regroupements.empty? && c.date_creation < 1.week.ago }
                          .each do |c|
        c.enseignants.each do |ce|
          ce.destroy
        end
        c.destroy
      end
    end

    def orphan_ressources
      Ressource
        .all
        .select { |r| r.cours.empty? && r.devoirs.empty? }
        .each do |r|
        r.destroy
      end
    end
  end

  # Fonctions de data management relatives aux utilisateurs
  module User
    module_function

    def delete( uid )
      UserParameters.where( uid: uid ).destroy

      DevoirTodoItem.where( eleve_id: uid ).destroy

      Cours.where( enseignant_id: uid ).each do |cours|
        cours.devoirs.each do |devoir|
          devoir.destroy
        end
        cours.destroy
      end

      CreneauEmploiDuTempsEnseignant.where( enseignant_id: uid )
                                    .all
                                    .each do |ce|
        cours = Cours[ce.creneau_emploi_du_temps_id]
        ce.destroy
        cours.destroy if cours.enseignants.empty?
      end
    end

    def merge( target_uid, source_uid )
      # UserParameters.where( uid: uid ).destroy

      # DevoirTodoItem.where( eleve_id: uid ).destroy

      # Cours.where( enseignant_id: uid ).each do |cours|
      #   cours.devoirs.each do |devoir|
      #     devoir.destroy
      #   end
      #   cours.destroy
      # end

      # CreneauEmploiDuTempsEnseignant.where( enseignant_id: uid )
      #                               .all
      #                               .each do |ce|
      #   cid = ce.creneau_emploi_du_temps_id
      #   ce.destroy
      #   cid.destroy if cid.enseignants.empty?
      # end
    end
  end
end
