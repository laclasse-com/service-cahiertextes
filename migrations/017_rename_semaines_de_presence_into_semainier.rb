# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :creneaux_emploi_du_temps_salles ) do
            rename_column( :semaines_de_presence, :semainier )
        end

        alter_table( :creneaux_emploi_du_temps_regroupements ) do
            rename_column( :semaines_de_presence, :semainier )
        end
    end
end
puts 'applying 017_rename_semaines_de_presence_into_semainier.rb'
