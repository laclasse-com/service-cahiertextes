# frozen_string_literal: true

Sequel.migration do
    change do
        puts '016_drop_table_creneaux_emploi_du_temps_enseignants.rb'

        drop_table( :creneaux_emploi_du_temps_enseignants )
    end
end
