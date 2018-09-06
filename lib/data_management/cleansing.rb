# coding: utf-8
module DataManagement
    # Fonctions de nettoyage des données
    module Cleansing
        module_function

        module Timeslots
            module_function

            def unfinished
                Timeslot
                    .where( subject_id: '' )
                    .where( group_id: nil )
                    .all
                    .select { |c| c.ctime < 1.week.ago }
                    .each do |c|
                    c.enseignants.each(&:destroy)
                    c.destroy
                end
            end

            def deleted_and_unused
                timeslots = Timeslot.where( deleted: true )
                                    .all
                                    .select { |c| c.cours.empty? && c.devoirs.empty? }

                timeslots.each do |c|
                    c.enseignants.each(&:destroy)
                    c.locations.each do |location|
                        c.remove_location( location )
                    end
                end

                timeslots.each(&:destroy)
            end
        end

        def orphan_ressources
            Ressource.all
                     .select { |r| r.cours.empty? && r.devoirs.empty? }
                     .each(&:destroy)
        end
    end
end
