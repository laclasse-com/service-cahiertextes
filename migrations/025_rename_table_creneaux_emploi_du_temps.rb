# frozen_string_literal: true

Sequel.migration do
    change do
        rename_table( :creneaux_emploi_du_temps, :timeslots )

        alter_table( :timeslots ) do
            rename_column( :jour_de_la_semaine, :weekday )
            rename_column( :matiere_id, :subject_id )
            rename_column( :date_creation, :ctime )
            rename_column( :date_suppression, :dtime )
            rename_column( :debut, :start_time )
            rename_column( :fin, :end_time )
            rename_column( :regroupement_id, :group_id )
            rename_column( :semainier, :active_weeks )
        end

        alter_table( :cours ) do
            rename_column( :creneau_emploi_du_temps_id, :timeslot_id )
        end

        alter_table( :devoirs ) do
            rename_column( :creneau_emploi_du_temps_id, :timeslot_id )
        end

        rename_table( :creneaux_emploi_du_temps_salles, :timeslots_salles )

        alter_table( :timeslots_salles ) do
            rename_column( :creneau_emploi_du_temps_id, :timeslot_id )
            rename_column( :semainier, :active_weeks )
        end
    end
end
puts '025_rename_table_creneaux_emploi_du_temps.rb'
