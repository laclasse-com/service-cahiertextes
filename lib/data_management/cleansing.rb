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
        c.enseignants.each(&:destroy)
        c.destroy
      end
    end

    def orphan_ressources
      Ressource
        .all
        .select { |r| r.cours.empty? && r.devoirs.empty? }
        .each(&:destroy)
    end
  end
end
