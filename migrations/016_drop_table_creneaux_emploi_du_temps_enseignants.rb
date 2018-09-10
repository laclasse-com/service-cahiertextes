# frozen_string_literal: true

Sequel.migration do
    change do
        drop_table( :creneaux_emploi_du_temps_enseignants )
    end
end
puts 'applying 016_drop_table_creneaux_emploi_du_temps_enseignants.rb'
