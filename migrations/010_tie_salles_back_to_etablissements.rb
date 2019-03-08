# frozen_string_literal: true

Sequel.migration do
    up do
        puts '010_tie_salles_back_to_etablissements.rb'

        alter_table( :salles ) do
            add_foreign_key :etablissement_id, :etablissements, null: true
        end
    end

    down do
        alter_table( :salles ) do
            drop_foreign_key :etablissement_id
        end
    end
end
