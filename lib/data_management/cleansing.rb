module DataManagement
  # Fonctions de nettoyage des données
  module Cleansing
    module_function

    module Creneaux
      module_function

      def unfinished
        CreneauEmploiDuTemps
          .where( matiere_id: '' )
          .where( regroupement_id: nil )
          .all
          .select { |c| c.date_creation < 1.week.ago }
          .each do |c|
          c.enseignants.each(&:destroy)
          c.destroy
        end
      end

      def deleted_and_unused
        creneaux = CreneauEmploiDuTemps.where( deleted: true )
                                       .all
                                       .select { |c| c.cours.empty? && c.devoirs.empty? }

        creneaux.each do |c|
          c.enseignants.each(&:destroy)
          c.salles.each do |salle|
            c.remove_salle( salle )
          end
        end

        creneaux.each(&:destroy)
      end
    end

    def orphan_ressources
      Ressource.all
               .select { |r| r.cours.empty? && r.devoirs.empty? }
               .each(&:destroy)
    end
  end
end
