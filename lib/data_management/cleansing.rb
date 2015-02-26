# -*- coding: utf-8 -*-

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

    def orphan_ressources
      Ressource
        .all
        .select { |r| r.cours.empty? && r.devoirs.empty? }
        .each do |r|
        r.destroy
      end
    end
  end
end
