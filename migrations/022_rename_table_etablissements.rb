# frozen_string_literal: true

Sequel.migration do
    change do
        puts '022_rename_table_etablissements.rb'

        rename_table( :etablissements, :structures )

        alter_table( :structures ) do
            rename_column( :debut_annee_scolaire, :schoolyear_start )
            rename_column( :fin_annee_scolaire, :schoolyear_end )
            rename_column( :date_premier_jour_premiere_semaine, :first_day_of_first_week )
        end

        alter_table( :imports ) do
            rename_column( :etablissement_id, :structure_id )
        end

        alter_table( :matchables ) do
            rename_column( :etablissement_id, :structure_id )
        end

        alter_table( :salles ) do
            rename_column( :etablissement_id, :structure_id )
        end

        alter_table( :creneaux_emploi_du_temps ) do
            rename_column( :etablissement_id, :structure_id )
        end
    end
end
