# -*- coding: utf-8 -*-

require_relative '../models/models'

module DataManagement
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
        cid = ce.creneau_emploi_du_temps_id
        ce.destroy
        cid.destroy if cid.enseignants.empty?
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
